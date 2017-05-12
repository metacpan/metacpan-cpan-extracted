start plackup -I../../lib --host 127.0.0.1 --port 8080 app_passwd.psgi --access-log app_passwd.psgi.log
ping 127.0.0.1 -n 2 > nul
start "" http://localhost:8080/ftree?type=;passwd=;lang=gb