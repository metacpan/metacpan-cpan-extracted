mysqldump -u barbie --skip-add-locks --add-drop-table --skip-disable-keys --skip-extended-insert eventcode >cgi-bin/db/eventcode-backup.sql
mysqldump -u barbie --create-options --add-drop-table --no-data eventcode >cgi-bin/db/eventcode-schema.sql
