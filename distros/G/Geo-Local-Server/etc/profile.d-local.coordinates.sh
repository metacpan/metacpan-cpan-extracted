#Name: perl-Geo-Local-Server
#Summary: Sets the environment variable from the file /etc/local.coordinates
if [ -r /etc/local.coordinates -a -x /usr/bin/local.coordinates ]; then
  export COORDINATES_WGS84_LON_LAT_HAE=`/usr/bin/local.coordinates`
fi
