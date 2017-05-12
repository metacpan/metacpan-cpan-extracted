#!/bin/sh

function cmd_to_devnull() {
    $* > /dev/null 2>/dev/null
    if test $? -ne 0
    then
        echo "[-] Command \"$*\" failed"
        exit 1
    fi
}

KS_VERSION=$(grep "VERSION =" lib/Keystone.pm | awk -F\' '{print $2}')

echo "[+] Adding GIT tag v$KS_VERSION"
cmd_to_devnull git tag v$KS_VERSION
cmd_to_devnull git push origin v$KS_VERSION


echo ""
echo ""
echo "~~~~~~~~~~~~ CPAN ~~~~~~~~~~~~~~"
echo "[+] Genere CPAN archive"
if test ! -d pkgs/cpan
then
    mkdir pkgs/cpan
fi
cmd_to_devnull scripts/gen_cpan_zip.sh
echo "[+] You can upload pkgs/cpan/Keystone-$KS_VERSION.zip to : https://pause.perl.org/pause/authenquery?ACTION=add_uri"

echo ""
echo ""
echo "~~~~~~~~~~ ArchLinux ~~~~~~~~~~~"
echo "[+] Genere archlinux package"

cd pkgs/archlinux
sed -i -r "s/pkgver=.+/pkgver=$KS_VERSION/g" PKGBUILD

SHA_SUMS=$(makepkg -g 2>/dev/null)
sed -i -r "s/sha256sums=.+/$SHA_SUMS/g" PKGBUILD

cmd_to_devnull mksrcinfo
cmd_to_devnull chmod 0644 PKGBUILD .SRCINFO
cmd_to_devnull git add PKGBUILD .SRCINFO
git commit -m v$KS_VERSION >/dev/null 2>/dev/null
cmd_to_devnull git push
cmd_to_devnull makepkg -f --source

echo "[+] Keystone v$KS_VERSION released !"
