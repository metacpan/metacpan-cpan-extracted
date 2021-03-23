use strict;

use Test::More;

push @INC, qw(blib/script) if -d 'blib';
unshift @INC, qw(t) if -d 't';
require 'testlib.pl';

eval { require Pod::Parser } or
	plan skip_all => qq(No Pod::Parser\n$@);

package File::Rename::Test::Parser;
our @ISA = qw(Pod::Parser);
our $key = __PACKAGE__;

sub begin_pod { shift->{$key} = []; }
sub command { return }
sub textblock { return }
sub interior_sequence { return }
sub verbatim {
    my ($self, $text) = @_;
    push @{$self->{$key}}, $text;
}

sub data { @{shift->{$key}} }

package main;

my $generic = 'rename';
my $script = script_name();
eval { require($script) } or
    BAIL_OUT qq{Can't require $script\n$@};

my $inc_script = $INC{$script};
BAIL_OUT "\$INC($script) = '$inc_script', missing\n" 
    unless $inc_script and -e $inc_script;  

my $parser = File::Rename::Test::Parser->new;
$parser->parse_from_file( $inc_script );
my @examples = grep /\s+$generic\s/, $parser->data;

#########################

# Insert your test code below, the Test::More
# module is use()ed here so read its man page
# ( perldoc Test::More ) 
# for help writing this test script.

plan tests => 2 + (@examples || 1);
like( $inc_script, qr{/ $script \z}msx,
	"required $script is $inc_script");
ok( scalar(@examples) > 1,
	"enough examples in $inc_script" );
# Larry Wall wrote 2 examples in 1992!

unshift @INC, 't' if -d 't';
require 'testlib.pl';

for ( @examples ) {
    s/\n+\z//;
    my $example = $_;
    s/\A\s+$generic\s+//;
    
    my @args = split;
    for (@args) { s/\A'(.*)'\z/$1/; }

    my $dir = tempdir();
    create(qw(1 foo.bak baa));
    chdir $dir or die $!;
    mkdir 'my_new_dir' or die $!;

    if ( $args[-1] =~ /\A\*/ ) {
	my @glob = glob(pop @args);
	push @args, @glob;
    }

    my $ok = eval { main_argv( @args ); 1 }; 
    ok( $ok, "example:$example" );
    diag $@ unless $ok;

    chdir File::Spec->updir or die $!;
    File::Path::rmtree($dir) or die $!;
}
	
