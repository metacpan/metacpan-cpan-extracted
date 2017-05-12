perl Makefile.PL
make
make install
mkdir /usr/local/EdgeExpressDB
cp -rp sql /usr/local/EdgeExpressDB/
cp -rp scripts /usr/local/EdgeExpressDB/bin
cp -rp www /usr/local/EdgeExpressDB/www
echo
echo "===== please extend your PATH to include"
echo "export PATH=\$PATH:/usr/local/EdgeExpressDB/bin"
