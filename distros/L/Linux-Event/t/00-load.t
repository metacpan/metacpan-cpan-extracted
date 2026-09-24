use v5.36;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
use JSON::PP qw(decode_json);
use CPAN::Meta::YAML ();

sub _slurp ($path) {
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    my $src = <$fh>;
    close $fh;
    return $src;
}

use_ok('Linux::Event');
use_ok('Linux::Event::Loop');

use_ok('Linux::Event::IO');
use_ok('Linux::Event::IO::Pipe');
use_ok('Linux::Event::IO::TTY');
use_ok('Linux::Event::IO::Sock');
use_ok('Linux::Event::IO::Sock::Stream');
use_ok('Linux::Event::IO::Sock::Listener');
use_ok('Linux::Event::IO::Sock::Dgram');

use_ok('Linux::Event::Kernel');
use_ok('Linux::Event::Kernel::Timer');
use_ok('Linux::Event::Kernel::Signal');
use_ok('Linux::Event::Kernel::Event');
use_ok('Linux::Event::Kernel::Inotify');
use_ok('Linux::Event::Kernel::Inotify::Watch');
use_ok('Linux::Event::Kernel::Inotify::Event');
use_ok('Linux::Event::Kernel::Process');

use_ok('Linux::Event::TLS');
use_ok('Linux::Event::Framer');
use_ok('Linux::Event::Error');
use_ok('Linux::Event::Address');

my $loop = Linux::Event::Loop->new;
ok($loop, 'created loop');

my $root = File::Spec->catdir($Bin, '..');
my $makefile_src = _slurp(File::Spec->catfile($root, 'Makefile.PL'));
my ($public_module_block) = $makefile_src =~
    /my \@public_modules = qw\(\s*(.*?)\s*\);/s;
ok(defined $public_module_block,
    'Makefile.PL declares the public module source of truth');

my $distribution_version = Linux::Event->VERSION;
my @public_modules = grep { length }
    split /\s+/, ($public_module_block // '');
for my $module (@public_modules) {
    (my $file = "$module.pm") =~ s{::}{/}g;
    require $file;
    is($module->VERSION, $distribution_version,
        "$module version matches Linux::Event $distribution_version");
}

my $meta_json = decode_json(
    _slurp(File::Spec->catfile($root, 'META.json'))
);
is($meta_json->{version}, $distribution_version,
    'META.json distribution version matches Linux::Event');
for my $module (@public_modules) {
    is($meta_json->{provides}{$module}{version}, $distribution_version,
        "META.json $module version matches distribution");
}

my $meta_yml_docs = CPAN::Meta::YAML->read(
    File::Spec->catfile($root, 'META.yml')
);
ok($meta_yml_docs && @$meta_yml_docs, 'META.yml parses');
if ($meta_yml_docs && @$meta_yml_docs) {
    my $meta_yml = $meta_yml_docs->[0];
    is($meta_yml->{version}, $distribution_version,
        'META.yml distribution version matches Linux::Event');
    for my $module (@public_modules) {
        is($meta_yml->{provides}{$module}{version}, $distribution_version,
            "META.yml $module version matches distribution");
    }
}

done_testing;
