#!/usr/bin/env bash

openssl genrsa 1024 > server.key
openssl req -new -x509 -nodes -sha1 -days 365 -key server.key > server.cert
