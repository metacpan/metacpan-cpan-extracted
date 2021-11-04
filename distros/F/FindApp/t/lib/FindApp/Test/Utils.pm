package FindApp::Test::Utils;

#################################################################

use v5.10;
use utf8;
use strict;
use warnings;

use Carp;
use File::Find ();  # mustn't import!
use FindBin;
use Package::Stash;
use Test::More;

#################################################################

sub   cmp_two_arrays     (  $$ ) ;
sub   find               (  &@ ) ;
sub   his_subs           (  $  ) ;
sub   modules_in_libdirs (  @  ) ;
sub   run_tests          (     ) ;
sub   sort_modules       (  @  ) ;
sub __TEST_CLASS__       (     ) ;
sub __TEST_PACKAGE__     (     ) ;

use Exporter     qw(import);
our @EXPORT_OK = (
    qw(
        module2test
        modules_in_libdirs
        run_tests
    ),
    <__TEST_{CLASS,PACKAGE}__>,
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

#################################################################

# duplicated because can't let test framework rely on stuff
# being tested
sub his_subs($) {
    my $package = shift;

    my @subs = grep { $_ ne "run_tests" && /_tests$/ } 
              Package::Stash->new($package)->list_all_symbols("CODE");
    return sort @subs;
}

sub run_tests() {
    my $package = caller;
    my @tests = @_;
    unless (@tests) {
        @tests = map { /(.+)_tests$/ } grep /_tests$/, his_subs($package);
    }
    for my $test (@tests) {
        my @words = split /_+/, $test;
        note("==== Running @words tests ====");
        my $subname = "${package}::${test}_tests";
        no strict "refs";
        &$subname;
    }
    done_testing();
}

sub modules_in_libdirs(@) {
    my @libs = @_ ? @_ : "lib";
    my @modules;
    for my $libdir (@libs) {
        find {
            / \.pm \z /x                || return;
            for (substr($File::Find::name, 1+length($libdir))) {
                s= \.pm \z ==x          || die "no pm in $_";
                s= /       =::=gx; #    || die "no slash in $_";
                push @modules, $_;
            }
        } $libdir;
    }
    return sort_modules @modules;
}

sub find(&@) { 
    my($with, @where) = @_;
    @where = qw(.) unless @where;
    return File::Find::find($with, @where);
}

# This has to be its own thing so we don't accidentally 
# rely on something we're testing.  Otherwise we'd just
# use sort_packages() from FindApp::Utils::Package.
sub sort_modules(@) {
    my @modules = do {
        map  { $_->[0] }
        sort { cmp_two_arrays(
               $a->[1]  => $b->[1])
                        ||
               $a->[0] cmp $b->[0]
        }
        map  [ $_ => [split /::/] ], 
        @_;
    };
    return @modules;
}

sub cmp_two_arrays($$) {
    my($a, $b) = @_;
    return @$a <=> @$b
    unless @$a  == @$b;
    for my $i (0 .. $#$a) {
        return $a->[$i] cmp $b->[$i]
        unless $a->[$i]  eq $b->[$i];
    }
    return 0;
}

sub module2test(_) {
    my($module) = @_;
    require    FindApp::Utils::Paths;
    my $path = FindApp::Utils::Paths::module2path($module);
    for ($path) {
        s/ \. p[lm] \z/.t/x;
        s! _+ (?#please don't) !-!xg;
        s! ^      ( \pL )  !\l$1!x      ;
        s! \pP \K ( \pL )  !\l$1!xg     ;
    }
    return $path;
}

# This one returns a string.
sub __TEST_PACKAGE__( ) {
    state $Test_Package;
    return $Test_Package if $Test_Package;
    my $orig = "$FindBin::Bin/$FindBin::Script";
    my $test_path = $orig;
    for ($test_path) {
        s! -+ (?#please don't) !_!xg;
        s! \.t $               !!x      || confess "$orig not a test file (#1)";
        s! ( .*/ )? t /        !!x      || confess "$orig not a test file (#2)";
        s! ^      ( \pL )  !\u$1!x      || confess "$orig not a test file (#3)";
        s! \pP \K ( \pL )  !\u$1!xg     ; # || confess "$orig not a test file (#4)";
        $Test_Package = join "::" => split "/";
    }
    return $Test_Package;
}

# This one returns an object.
sub __TEST_CLASS__( ) {
    require FindApp::Utils::Package::Object;
    new     FindApp::Utils::Package::Object  __TEST_PACKAGE__;
}

1;

__END__


__END__

=head1 NAME

FindApp::Test::Utils - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

=head1 LICENCE AND COPYRIGHT
