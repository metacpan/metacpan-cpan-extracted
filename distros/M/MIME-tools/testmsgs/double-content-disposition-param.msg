From: Test <null@example.com>
To: Test <null@example.com>
Subject: Ambiguous boundary
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="bar"

--bar
Content-Type: text/plain

Whatever

--bar
Content-Type: application/octet-stream
Content-Transfer-Encoding: base64
Content-Disposition: attachment; name="wookie.exe"; name="innocuous.txt"

Z290Y2hhCg==

--bar--
