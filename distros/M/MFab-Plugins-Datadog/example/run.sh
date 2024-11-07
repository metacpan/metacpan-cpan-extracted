#!/bin/sh

cd /app/example
while :; do
  ./hypnotoad -f ./web
  echo restarting
  sleep 1
done
