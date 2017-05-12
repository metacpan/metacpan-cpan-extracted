start plackup --host 127.0.0.1 --port 8080 app.psgi --access-log app.psgi.log
ping 127.0.0.1 -n 2 > nul
start "" http://localhost:8080/ftree?type=;passwd=;lang=gb