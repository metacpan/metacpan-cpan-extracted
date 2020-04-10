use strict;
use warnings;

use Path::Tiny;
my $code = path('t', '03-pluginbundle-server.t')->slurp_utf8;

my $new_bugtracker = q!web => 'https://github.com/karenetheridge/Dist-Zilla-PluginBundle-Author-ETHER/issues'!;
$code =~ s/bugtracker => \{\s+\K[^}]+(,\s+)/$new_bugtracker$1/ms;

$code =~ s/server => \$server,(\s+)\K/bugtracker => 'github',$1/ms;

my $exception = q{ if $server eq 'github';
        like($exception, qr/bugtracker cannot be github unless server = github/,
            "bugtracker = github cannot be used with server = $server"), next if $server ne 'github';};
$code =~ s/^(\s)+is \$exception[^;]+\K;/$exception$1/ms;

eval $code;
die $@ if $@;
