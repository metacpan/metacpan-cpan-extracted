#!/usr/bin/env bash
# Check that the packed binary needs no shared library beyond the documented set.
#   check-binary-libs.sh <binary>   check
#   check-binary-libs.sh --list     print the documented runtime libs (one line)
set -euo pipefail

# libcrypt: the pp loader executable links libperl, which links libcrypt.so.1. The loader runs
# before PAR extracts anything, so a bundled copy (pp -l) cannot help: the target must have it.
# Debian and Ubuntu always do; install libxcrypt-compat on RHEL/Fedora/Amazon Linux and Arch.
# The README names the same set.
#
# macOS (Darwin): the needed libraries come from `otool -L`; the system libraries below ship
# with every macOS, so the documented runtime set there is empty.
case "$(uname -s)" in
  Darwin)
    RUNTIME_LIBS=()
    BASE_LIBS=(libSystem.B 'libc\+\+.1' 'libc\+\+abi' libobjc.A libiconv.2 libresolv.9
               libz.1 libcharset.1 libncurses.5.4 libm libpthread libdl)
    NEEDS_TOOL=otool
    SO_PATTERN=(-name '*.so' -o -name '*.bundle' -o -name '*.dylib' -o -name '*.so.*') ;;
  *)
    RUNTIME_LIBS=(libcrypt)
    BASE_LIBS=(libc libm libpthread libdl librt libgcc_s 'ld-linux-.*' linux-vdso libperl)
    NEEDS_TOOL=ldd
    # The glibc floor: the highest GLIBC_x.y symbol version any packed object requires. The Linux
    # binaries build in a bullseye (glibc 2.31) image, so the target needs glibc 2.31 or newer
    # (RHEL 9 and Ubuntu 20.04 included). The README names the same ceiling.
    GLIBC_MAX=2.31
    SO_PATTERN=(-name '*.so' -o -name '*.so.*') ;;
esac

if [ "${1:-}" = "--list" ]; then echo "${RUNTIME_LIBS[*]:-}"; exit 0; fi

command -v "$NEEDS_TOOL" >/dev/null 2>&1 || { echo "FAIL: $NEEDS_TOOL is not installed" >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "FAIL: unzip is not installed" >&2; exit 1; }
BIN=$(perl -MCwd=abs_path -e 'print abs_path(shift) // ""' "${1:?usage: check-binary-libs.sh <binary> | --list}")
[ -f "$BIN" ] || { echo "FAIL: no such file: $BIN" >&2; exit 1; }
allowed=$(IFS='|'; echo "${RUNTIME_LIBS[*]:-}|${BASE_LIBS[*]}")
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

rc=0
unzip -qq -o "$BIN" -d "$work/par" || rc=$?       # exit 1 = warning (bytes before the zip)
[ "$rc" -le 1 ] || { echo "FAIL: cannot unpack the PAR archive (unzip exit $rc)" >&2; exit 1; }

objects=("$BIN")
while IFS= read -r f; do objects+=("$f"); done \
  < <(find "$work/par" -type f \( "${SO_PATTERN[@]}" \) -print | sort)
# The loader executable plus at least one XS shared object (List::Util, Cwd, ...) must be there.
[ "${#objects[@]}" -ge 2 ] || { echo "FAIL: no shared objects inside $BIN" >&2; exit 1; }

: > "$work/needs"
# needed_libs OBJECT: prints one library name per line (version suffixes stripped).
needed_libs() {
  if [ "$NEEDS_TOOL" = ldd ]; then
    ldd "$1" >"$work/tool.out" 2>"$work/tool.err" \
      || { grep -q 'not a dynamic executable' "$work/tool.err" "$work/tool.out" && return 0; \
           echo "FAIL: ldd failed on ${1#"$work/par/"}: $(cat "$work/tool.err")" >&2; exit 1; }
    awk '$1 ~ /\.so/ { lib = $1; sub(/.*\//, "", lib); sub(/\.so.*/, "", lib); print lib }' "$work/tool.out"
  else
    otool -L "$1" >"$work/tool.out" 2>"$work/tool.err" \
      || { echo "FAIL: otool failed on ${1#"$work/par/"}: $(cat "$work/tool.err")" >&2; exit 1; }
    # Line 1 is the file name; a dylib lists its own install name first, which is not a need.
    is_dylib=; [[ "$1" == *.dylib ]] && is_dylib=1
    awk -v dylib="$is_dylib" \
      'NR > 1 && /^[ \t]/ { if (dylib && !skipped) { skipped = 1; next }
         lib = $1; sub(/.*\//, "", lib); sub(/\.dylib$/, "", lib); print lib }' "$work/tool.out"
  fi
}
for obj in "${objects[@]}"; do
  needed_libs "$obj" | sort -u | awk -v obj="${obj#"$work/par/"}" '{ print $0 "\t" obj }' >> "$work/needs"
done

[ -s "$work/needs" ] || { echo "FAIL: ldd found no shared libs; a Perl binary always needs libc" >&2; exit 1; }

echo "Shared libs the binary needs on the target (${#objects[@]} objects checked):"
cut -f1 "$work/needs" | sort -u | sed 's/^/  /'

undocumented=$(cut -f1 "$work/needs" | sort -u | grep -vxE "$allowed" || true)
if [ -n "$undocumented" ]; then
  for lib in $undocumented; do
    printf '::error::undocumented runtime lib %s, needed by: %s\n' "$lib" \
      "$(awk -F'\t' -v l="$lib" '$1 == l {print $2}' "$work/needs" | sort -u | paste -sd' ')" >&2
  done
  echo "FAIL: libs outside the documented runtime set (${RUNTIME_LIBS[*]:-none})" >&2
  exit 1
fi
echo "runtime-libs check: only the documented libs are needed"

# glibc floor (Linux): every object's undefined GLIBC_x.y symbol versions, highest one wins.
if [ "$NEEDS_TOOL" = ldd ]; then
  command -v objdump >/dev/null 2>&1 || { echo "FAIL: objdump is not installed (binutils)" >&2; exit 1; }
  : > "$work/glibc"
  for obj in "${objects[@]}"; do
    objdump -T "$obj" 2>/dev/null | awk '/\*UND\*/' | grep -o 'GLIBC_[0-9][0-9.]*' \
      | sed 's/^GLIBC_//' | sort -u | sed "s|\$|\t${obj#"$work/par/"}|" >> "$work/glibc" || true
  done
  floor=$(cut -f1 "$work/glibc" | sort -uV | tail -n 1)
  [ -n "$floor" ] || { echo "FAIL: no GLIBC_ symbol versions found; a Perl binary always has them" >&2; exit 1; }
  echo "glibc floor: $floor (documented ceiling: $GLIBC_MAX)"
  if [ "$(printf '%s\n%s\n' "$floor" "$GLIBC_MAX" | sort -V | tail -n 1)" != "$GLIBC_MAX" ]; then
    printf '::error::glibc %s is above the documented %s, needed by: %s\n' "$floor" "$GLIBC_MAX" \
      "$(awk -F'\t' -v f="$floor" '$1 == f {print $2}' "$work/glibc" | sort -u | paste -sd' ')" >&2
    echo "FAIL: the binary needs glibc $floor, above the documented $GLIBC_MAX" >&2
    exit 1
  fi
  echo "glibc check: floor $floor is within $GLIBC_MAX"
fi
