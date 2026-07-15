use strict;
use warnings;
use Test::More;
use Eshu;

sub ba { Eshu->indent_bash($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. simple function
{
	my $code = <<'END';
greet() {
	local name="$1"
	echo "Hello, ${name}!"
}
END
	is(ba($code), $code, 'Bash: simple function');
}

# 2. if/then/else/fi
{
	my $code = <<'END';
check_file() {
	local path="$1"
	if [ -f "$path" ]; then
		echo "file exists"
	elif [ -d "$path" ]; then
		echo "is a directory"
	else
		echo "not found"
	fi
}
END
	is(ba($code), $code, 'Bash: if/elif/else/fi');
}

# 3. for loop over array
{
	my $code = <<'END';
print_items() {
	local -a items=("$@")
	for item in "${items[@]}"; do
		echo "  - $item"
	done
}
END
	is(ba($code), $code, 'Bash: for loop over array');
}

# 4. while read loop
{
	my $code = <<'END';
count_lines() {
	local file="$1"
	local count=0
	while IFS= read -r line; do
		count=$((count + 1))
	done < "$file"
	echo "$count"
}
END
	is(ba($code), $code, 'Bash: while read loop');
}

# 5. case statement
{
	my $code = <<'END';
describe_extension() {
	local file="$1"
	case "${file##*.}" in
		sh|bash)
			echo "shell script"
			;;
		py)
			echo "Python"
			;;
		pl|pm)
			echo "Perl"
			;;
		*)
			echo "unknown"
			;;
	esac
}
END
	is(ba($code), $code, 'Bash: case statement');
}

# 6. until loop
{
	my $code = <<'END';
wait_for_port() {
	local host="$1" port="$2"
	until nc -z "$host" "$port" 2>/dev/null; do
		sleep 1
	done
}
END
	is(ba($code), $code, 'Bash: until loop');
}

# 7. getopts parsing
{
	my $code = <<'END';
parse_opts() {
	local verbose=0 output=''
	while getopts ':vo:' opt; do
		case "$opt" in
			v) verbose=1 ;;
			o) output="$OPTARG" ;;
			:) echo "Option -$OPTARG requires argument" >&2; return 1 ;;
			\?) echo "Unknown option -$OPTARG" >&2; return 1 ;;
		esac
	done
	shift $((OPTIND - 1))
}
END
	is(ba($code), $code, 'Bash: getopts parsing');
}

# 8. trap for cleanup
{
	my $code = <<'END';
run_with_cleanup() {
	local tmpdir
	tmpdir=$(mktemp -d)
	trap 'rm -rf "$tmpdir"' EXIT INT TERM
	do_work "$tmpdir"
}
END
	is(ba($code), $code, 'Bash: trap for cleanup');
}

# 9. process substitution
{
	my $code = <<'END';
diff_configs() {
	local a="$1" b="$2"
	diff <(sort "$a") <(sort "$b")
}
END
	is(ba($code), $code, 'Bash: process substitution');
}

# 10. pipe chain
{
	my $code = <<'END';
top_words() {
	local file="$1" n="${2:-10}"
	tr -s '[:space:]' '\n' < "$file" \
	| tr '[:upper:]' '[:lower:]' \
	| sort \
	| uniq -c \
	| sort -rn \
	| head -n "$n"
}
END
	is(ba($code), $code, 'Bash: pipe chain');
}

# 11. array manipulation
{
	my $code = <<'END';
array_contains() {
	local needle="$1"
	shift
	local -a haystack=("$@")
	for item in "${haystack[@]}"; do
		if [[ "$item" == "$needle" ]]; then
			return 0
		fi
	done
	return 1
}
END
	is(ba($code), $code, 'Bash: array contains check');
}

# 12. string manipulation
{
	my $code = <<'END';
trim() {
	local str="$1"
	str="${str#"${str%%[![:space:]]*}"}"
	str="${str%"${str##*[![:space:]]}"}"
	echo "$str"
}
END
	is(ba($code), $code, 'Bash: string trim');
}

# 13. numeric loop
{
	my $code = <<'END';
retry() {
	local n="$1" cmd=("${@:2}")
	for ((i=1; i<=n; i++)); do
		if "${cmd[@]}"; then
			return 0
		fi
		sleep "$i"
	done
	return 1
}
END
	is(ba($code), $code, 'Bash: C-style for loop retry');
}

# 14. here-string
{
	my $code = <<'END';
json_field() {
	local json="$1" field="$2"
	python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$field',''))" \
	<<< "$json"
}
END
	is(ba($code), $code, 'Bash: here-string to python');
}

# 15. subshell
{
	my $code = <<'END';
in_dir() {
	local dir="$1"
	shift
	(
	cd "$dir" || exit 1
	"$@"
	)
}
END
	is(ba($code), $code, 'Bash: run command in subshell');
}

# 16. associative array
{
	my $code = <<'END';
count_extensions() {
	local dir="$1"
	declare -A counts
	while IFS= read -r f; do
		ext="${f##*.}"
		counts["$ext"]=$((${counts["$ext"]:-0} + 1))
	done < <(find "$dir" -type f)
	for ext in "${!counts[@]}"; do
		echo "$ext: ${counts[$ext]}"
	done
}
END
	is(ba($code), $code, 'Bash: associative array word count');
}

# 17. error handling
{
	my $code = <<'END';
die() {
	echo "ERROR: $*" >&2
	exit 1
}

require_cmd() {
	local cmd="$1"
	if ! command -v "$cmd" &>/dev/null; then
		die "Required command not found: $cmd"
	fi
}
END
	is(ba($code), $code, 'Bash: die and require_cmd');
}

# 18. recursive function
{
	my $code = <<'END';
factorial() {
	local n="$1"
	if ((n <= 1)); then
		echo 1
	else
		local prev
		prev=$(factorial $((n - 1)))
		echo $((n * prev))
	fi
}
END
	is(ba($code), $code, 'Bash: recursive factorial');
}

# 19. select menu
{
	my $code = <<'END';
pick_color() {
	PS3="Choose a color: "
	select color in Red Green Blue Quit; do
		case "$color" in
			Quit) break ;;
			"") echo "Invalid choice" ;;
			*) echo "You picked $color"; break ;;
		esac
	done
}
END
	is(ba($code), $code, 'Bash: select menu');
}

# 20. file processing
{
	my $code = <<'END';
prepend_header() {
	local file="$1" header="$2"
	local tmp
	tmp=$(mktemp)
	{
		echo "$header"
		cat "$file"
	} > "$tmp"
	mv "$tmp" "$file"
}
END
	is(ba($code), $code, 'Bash: prepend header to file');
}

# 21. logging utility
{
	my $code = <<'END';
LOG_LEVEL="${LOG_LEVEL:-INFO}"

log() {
	local level="$1"
	shift
	if [[ "$level" == "DEBUG" && "$LOG_LEVEL" != "DEBUG" ]]; then
		return
	fi
	echo "$(date -u +%FT%TZ) [$level] $*" >&2
}
END
	is(ba($code), $code, 'Bash: logging utility');
}

# 22. parallel execution
{
	my $code = <<'END';
run_parallel() {
	local -a pids=()
	for cmd in "$@"; do
		eval "$cmd" &
		pids+=($!)
	done
	local rc=0
	for pid in "${pids[@]}"; do
		wait "$pid" || rc=$?
	done
	return $rc
}
END
	is(ba($code), $code, 'Bash: parallel execution with wait');
}

# 23. lock file
{
	my $code = <<'END';
with_lock() {
	local lockfile="$1"
	shift
	exec 9>"$lockfile"
	if ! flock -n 9; then
		echo "Already running" >&2
		return 1
	fi
	"$@"
}
END
	is(ba($code), $code, 'Bash: lock file with flock');
}

# 24. config file parser
{
	my $code = <<'END';
load_config() {
	local file="$1"
	while IFS='=' read -r key value; do
		key="${key%%#*}"
		key="${key// /}"
		value="${value%%#*}"
		value="${value%"${value##*[^[:space:]]}"}"
		if [[ -n "$key" ]]; then
			export "$key=$value"
		fi
	done < "$file"
}
END
	is(ba($code), $code, 'Bash: config file parser');
}

# 25. spinner
{
	my $code = <<'END';
with_spinner() {
	local pid msg="$1"
	shift
	"$@" &
	pid=$!
	local frames='|/-\'
	local i=0
	while kill -0 "$pid" 2>/dev/null; do
		printf "\r%s %s" "$msg" "${frames:$((i%4)):1}"
		sleep 0.1
		i=$((i+1))
	done
	printf "\r%s done\n" "$msg"
	wait "$pid"
}
END
	is(ba($code), $code, 'Bash: progress spinner');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
	my $in = <<'END';
backup() {
local src="$1" dst="$2"
if [ ! -d "$src" ]; then
echo "source not found" >&2
return 1
fi
mkdir -p "$dst"
cp -a "$src/." "$dst/"
}
END
	my $exp = <<'END';
backup() {
	local src="$1" dst="$2"
	if [ ! -d "$src" ]; then
		echo "source not found" >&2
		return 1
	fi
	mkdir -p "$dst"
	cp -a "$src/." "$dst/"
}
END
	is(ba($in), $exp, 'Bash: unindented backup function normalised');
}

# 27
{
	my $in = <<'END';
is_integer() {
local val="$1"
case "$val" in
''|*[!0-9-]*) return 1 ;;
-) return 1 ;;
esac
return 0
}
END
	my $exp = <<'END';
is_integer() {
	local val="$1"
	case "$val" in
		''|*[!0-9-]*) return 1 ;;
		-) return 1 ;;
	esac
	return 0
}
END
	is(ba($in), $exp, 'Bash: unindented is_integer normalised');
}

# 28
{
	my $in = <<'END';
join_by() {
local IFS="$1"
shift
echo "$*"
}
END
	my $exp = <<'END';
join_by() {
	local IFS="$1"
	shift
	echo "$*"
}
END
	is(ba($in), $exp, 'Bash: unindented join_by normalised');
}

# 29
{
	my $in = <<'END';
read_password() {
local prompt="${1:-Password: }"
local password
if [ -t 0 ]; then
read -rsp "$prompt" password
echo
else
read -r password
fi
echo "$password"
}
END
	my $exp = <<'END';
read_password() {
	local prompt="${1:-Password: }"
	local password
	if [ -t 0 ]; then
		read -rsp "$prompt" password
		echo
	else
		read -r password
	fi
	echo "$password"
}
END
	is(ba($in), $exp, 'Bash: unindented read_password normalised');
}

# 30
{
	my $in = <<'END';
find_files() {
local dir="$1" ext="$2"
local -a found=()
while IFS= read -r -d '' f; do
found+=("$f")
done < <(find "$dir" -name "*.$ext" -print0)
printf '%s\n' "${found[@]}"
}
END
	my $exp = <<'END';
find_files() {
	local dir="$1" ext="$2"
	local -a found=()
	while IFS= read -r -d '' f; do
		found+=("$f")
	done < <(find "$dir" -name "*.$ext" -print0)
	printf '%s\n' "${found[@]}"
}
END
	is(ba($in), $exp, 'Bash: unindented find_files normalised');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
	"setup_env() {\nexport PATH=\"\$HOME/.local/bin:\$PATH\"\n[[ -f \"\$HOME/.env\" ]] && source \"\$HOME/.env\"\nulimit -n 65536\n}\n",
	"watch_dir() {\nlocal dir=\"\$1\"\ninotifywait -m -r -e create,modify,delete \"\$dir\" 2>/dev/null | while read -r path event file; do\necho \"[\$event] \$path\$file\"\ndone\n}\n",
	"run_sql() {\nlocal db=\"\$1\" sql=\"\$2\"\npsql -U postgres -d \"\$db\" -c \"\$sql\" -t -A\n}\n",
	"semver_gt() {\nlocal v1=\"\$1\" v2=\"\$2\"\npython3 -c \"from packaging.version import Version; exit(0 if Version('\$v1') > Version('\$v2') else 1)\"\n}\n",
	"generate_password() {\nlocal len=\"\${1:-16}\"\nLC_ALL=C tr -dc 'A-Za-z0-9!@#\$%^&*' </dev/urandom | head -c \"\$len\"\necho\n}\n",
	"check_deps() {\nlocal -a missing=()\nfor cmd in \"$@\"; do\ncommand -v \"\$cmd\" &>/dev/null || missing+=(\"\$cmd\")\ndone\nif [[ \${#missing[@]} -gt 0 ]]; then\necho \"Missing: \${missing[*]}\" >&2\nreturn 1\nfi\n}\n",
	"git_branch() {\ngit rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'detached'\n}\n",
	"ensure_dir() {\nfor dir in \"\$@\"; do\n[ -d \"\$dir\" ] || mkdir -p \"\$dir\" || { echo \"Cannot create \$dir\" >&2; return 1; }\ndone\n}\n",
	"encode_base64() {\nif command -v base64 &>/dev/null; then\necho -n \"\$1\" | base64\nelif command -v openssl &>/dev/null; then\necho -n \"\$1\" | openssl enc -base64\nfi\n}\n",
	"elapsed() {\nlocal start=\"\$1\" end=\"\${2:-\$(date +%s)}\"\nlocal diff=\$((end - start))\nprintf '%02d:%02d:%02d' \$((diff/3600)) \$(((diff%3600)/60)) \$((diff%60))\n}\n",
) {
	my $once = ba($snippet);
	is(ba($once), $once, 'Bash: snippet idempotent');
}

done_testing;
