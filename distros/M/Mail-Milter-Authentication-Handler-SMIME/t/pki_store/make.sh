#!/bin/bash

mkdir -p certs/ca
openssl genrsa \
  -out certs/ca/my-root-ca.key.pem \
  2048

openssl req \
  -x509 \
  -new \
  -nodes \
  -key certs/ca/my-root-ca.key.pem \
  -days 365000 \
  -out certs/ca/my-root-ca.crt.pem \
  -subj "/C=AU/ST=/L=/O=FastMail SMIME Test Signing Authority/CN=testca.example.net"

mkdir -p certs/{servers,tmp}

mkdir -p "certs/servers/test.example.com"
openssl genrsa \
  -out "certs/servers/test.example.com/privkey.pem" \
  2048

openssl req -new \
  -key "certs/servers/test.example.com/privkey.pem" \
  -out "certs/tmp/test.example.com.csr.pem" \
  -subj "/C=AU/ST=/L=/O=FastMail Test User Vert/CN=test@example.com"

openssl x509 \
  -req -in certs/tmp/test.example.com.csr.pem \
  -CA certs/ca/my-root-ca.crt.pem \
  -CAkey certs/ca/my-root-ca.key.pem \
  -CAcreateserial \
  -out certs/servers/test.example.com/cert.pem \
  -days 365000

cat \
  "certs/servers/test.example.com/privkey.pem" \
  "certs/servers/test.example.com/cert.pem" \
  > "certs/servers/test.example.com/server.pem"


cat \
  "certs/ca/my-root-ca.crt.pem" \
  > "certs/servers/test.example.com/chain.pem"

cat \
  "certs/servers/test.example.com/cert.pem" \
  "certs/ca/my-root-ca.crt.pem" \
  > "certs/servers/test.example.com/fullchain.pem"

echo "To: test@example.com
From: Marc Bradshaw <marc@fastmail.com>
Subject: SMIME Testing
Message-ID: <56CA812E.10308@fastmail.com>
Date: Mon, 22 Feb 2016 14:31:58 +1100" > smime.eml

echo "This is an SMIME Signed Message.

It should validate properly until it's certificates expire." > smime.body

openssl smime -sign \
    -in smime.body \
    -out smime.body.signed \
    -text \
    -signer certs/servers/test.example.com/cert.pem \
    -inkey certs/servers/test.example.com/privkey.pem

cat smime.body.signed >> smime.eml
/bin/rm smime.body
/bin/rm smime.body.signed

cp smime.eml smime2.eml
sed -i -r "s|It should validate properly until it's certificates expire.|It has been tampered with, and should NOT validate correctly.|" smime2.eml

echo "References: <56CA812E.10308@fastmail.com>
Subject: SMIME Forward Test
To: test2@example.com
From: Marc Bradshaw <marc@fastmail.com>
X-Forwarded-Message-Id: <56CA812E.10308@fastmail.com>
Message-ID: <56CB9278.1090104@fastmail.com>
Date: Tue, 23 Feb 2016 09:58:00 +1100
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101
 Thunderbird/38.5.1
MIME-Version: 1.0
In-Reply-To: <56CA812E.10308@fastmail.com>
Content-Type: multipart/mixed;
 boundary=\"------------060706030404070802070003\"

This is a multi-part message in MIME format.
--------------060706030404070802070003
Content-Type: text/plain; charset=utf-8; format=flowed
Content-Transfer-Encoding: 7bit

Unsigned Forwarded Signed Message

--------------060706030404070802070003
Content-Type: message/rfc822;
 name=\"SMIME Testing.eml\"
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment;
 filename=\"SMIME Testing.eml\"
" > smime3.eml
cat smime.eml >> smime3.eml
echo "------F99A608E2DA19863D84275E8572D0438--" >> smime3.eml

