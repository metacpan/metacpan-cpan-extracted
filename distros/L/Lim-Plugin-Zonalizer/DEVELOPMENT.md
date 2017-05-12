# Development environment

Ubuntu 14.04 LTS

```
sudo add-apt-repository -y ppa:jelu/lim
sudo add-apt-repository -y ppa:jelu/couchdb
sudo add-apt-repository -y ppa:jelu/anyevent-http
sudo add-apt-repository -y ppa:jelu/zonemaster
sudo apt-get update
sudo apt-get -y install lim-agentd liblim-cli-perl liblim-protocol-rest-perl libxmlrpc-lite-perl libsoap-lite-perl libxmlrpc-transport-http-server-perl liblim-transport-http-perl libanyevent-rabbitmq-perl rabbitmq-server liburi-escape-xs-perl libanyevent-couchdb-perl build-essential nginx couchdb zonemaster-cli
sudo apt-get -y install libtest-manifest-perl libtest-pod-coverage-perl libtest-pod-perl libtest-checkmanifest-perl libperl-critic-perl libtest-perl-critic-perl libdevel-cover-perl perltidy
```

```
upstream backend {
  server localhost:8080;
  keepalive 16;
}

  gzip on;
  gzip_types *;
  gzip_proxied any;

  location /zonalizer/ {
    proxy_pass http://backend;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_buffering off;
  }
```

```
tee -a .bash_aliases <<EOF
export LC_ALL=\$LANG
PERL_MB_OPT="--install_base \"\$HOME/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=\$HOME/perl5"; export PERL_MM_OPT;
PERL_MM_USE_DEFAULT=1; export PERL_MM_USE_DEFAULT
export PERL5LIB=\$HOME/perl5/lib/perl5:\$HOME/lim-plugin-zonalizer/blib/lib:\$HOME/lim-plugin-zonalizer/blib/arch
export PATH="\$HOME/perl5/bin:\$PATH"
EOF
source .bash_aliases
echo -e "yes\nyes\no conf prerequisites_policy 'follow'\no conf build_requires_install_policy yes\no conf commit\nquit" | cpan
cpan Perl::Tidy && cpan Perl::Critic && cpan Perl::Critic::StricterSubs && cpan Test::PerlTidy && cpan Perl::Critic::Swift
```
