From: Test <null@example.com>
To: Test <null@example.com>
Subject: Exe smuggled in epilogue of mail with trailing whitespace in quoted boundary
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="FOO "

--FOO
Content-Type: text/plain

innocent text
--FOO--
--FOO 
Content-Type: application/x-msdownload
Content-Disposition: attachment; filename="evil.exe"

MZ fake executable payload, only visible to parsers that keep the quoted boundary value verbatim
--FOO --
