# docker-client

## Build status

[![pipeline status](https://gitlab.com/marghidanu/docker-client/badges/master/pipeline.svg)](https://gitlab.com/marghidanu/docker-client/-/commits/master)

## Development environment

```shell
vagrant up
vagrant ssh

sudo su -
cd /vagrant

perl Build.PL
./Build installdeps
./Build
./Build test
```