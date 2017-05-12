# $Id: TestSuite.pm 526 2017-04-15 01:52:05Z sync $
# Copyright 2009, 2010, 2014, 2017 Eric Pozharski <whynot@pozharski.name>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package DB;
sub get_fork_TTY { xterm_get_fork_TTY() }

package t::TestSuite;
use version 0.77; our $VERSION = version->declare( v0.1.9 );
# TODO:201406091242:whynot: Go B<parent()> whenever possible (perl v5.10.0 or something).
# http://www.cpantesters.org/cpan/report/5947de70-df50-11e3-a498-53c68706f0e4
use base   qw| Exporter |;
use lib     q|./blib/lib|;

use Carp;
use Module::Build;
use Cwd;
use File::Temp qw| tempfile tempdir |;

our %EXPORT_TAGS =
( diag => [qw| FAFTS_diag                       FAFTS_show_message |],
  temp => [qw| FAFTS_tempfile      FAFTS_tempdir      FAFTS_cat_fn |],
  mthd => [qw| FAFTS_prepare_method FAFTS_wrap FAFTS_wait_and_gain |],
  file => [qw| FAFTS_get_file   FAFTS_set_file   FAFTS_append_file |] );
our @EXPORT_OK = map @$_, values %EXPORT_TAGS;
our $Empty_MD5 = q|d41d8cd98f00b204e9800998ecf8427e|;

$ENV{PERL5LIB} = getcwd . q(/blib/lib);

=head1 DIAGNOSTIC OUTPUT

=over

=cut

=item B<FAFTS_diag()>

    use t::TestSuite qw/ :diag /;
    FAFTS_diag $@

Outputs through B<Test::More::diag()>.
Void if I<$ENV{QUIET}> is TRUE, I<@_> is empty, or
I<@_> consists of FALSEs.

If C<!-t> I<STDOUT> whatever (unless missing) is thrown in is collected
(with fancy header prepended) for later output.
C<Result: FAIL> or I<$ENV{FAFTS_VERBOSE}> will force such output just before
an unit would finish.

"Fancy header" looks like this:

    *** (tag+c04f): <t/unit+5467.t> [FAFTS_wrap] (132) ***

=over

=item *

Either:

=over

=item +

Some identifing mark set through I<$t::TestSuite::Diag_Tag> --
mostly in code cycling over a data-set.

=item +

Stack depth -- a placeholder otherwise.

=back

=item *

A filename of unit.

=item *

A subroutine in B<t::TestSuite> namespace what has something to diag.

=item *

A line number where aforementioned subroutine has been called.

=back

=cut

our $Diag_Tag;
my @precious;
sub FAFTS_diag ( @ )                                                    {
    unless( !$ENV{QUIET} && @_ && grep $_, @_                       )  {}
    elsif( (!-t STDOUT || $ENV{FAFTS_VERBOSE}) && @_ && grep $_, @_ )  {
        my @stck;
        my $dpth = 5;
        @stck = ( caller $dpth-- )[1,3,2]                                until
          @stck && $stck[1] =~ m{^t::TestSuite};
        $stck[1] = ( $stck[1] =~ m{([^:]+)$} )[0];
        push @precious,
          sprintf( qq|*** (%s): <%s> [%s] (%i) ***\n|,
            $Diag_Tag || $dpth + 1, @stck ),
          map { -1 == index( reverse( $_ ), "\n" ) ? qq|$_\n| : $_ } @_ }
    else                                                               {
        Test::More::diag( @_ )                                          }}

END { Test::More::diag( @precious )             if $? || $ENV{FAFTS_VERBOSE} }

=item B<FAFTS_show_message()>

    use t::TestSuite qw/ :diag /;
    FAFTS_show_message %arg

B<FAFTS_diag>s (debian config alike) contents of a I<%arg>.
Void if I<@_> is
empty.
If value of supposed key from I<%arg> evaluates to C<undef>
then silently replaces with C<(undef)>.

=back

=cut

sub FAFTS_show_message ( % ) {
    @_                                                              or return;
    my %message = @_;
    FAFTS_diag map sprintf( qq|%s: %s\n|,
      $_, defined $message{$_} ? $message{$_} : q|(undef)| ),
      sort keys %message      }

=head1 FILES AND DIRECTORIES

=over

=cut

=item B<FAFTS_tempfile()>

    use t::TestSuite qw/ :temp /;
    $tempfile = FAFTS_tempfile %args;

Creates a temporal file.
This file is scheduled for deletion when test-unit completes.
The file is named:
F<skip_$caller_$nick_XXXX>
Known parameters are:

=over

=item I<$caller>

If unset, reasonable default based on B<caller> return is provided.

=item I<$content>

If set will be fed into just created file.

=item I<$dir>

Requests file to be created in specific directory.
B<cwd()> isa default.

=item I<$nick>

Arbitrary identification what has meaning in calling code.
C<void> isa deafult.

=item I<$suffix>

Obvious.

=item I<$unlink>

If TRUE then just created temporal is removed.
Only filename what's left.

=back

Returns a filename.
Due to I<$args{dir}> defaulting filename is always fully qualified;
probably canonicalized.
A filehandle is implicitly closed.

=cut

my @Tempfiles = ( $$ );
sub FAFTS_tempfile ( % ) {
    my %args = @_;
    my $fn =
      sprintf q|skip_%s_%s_XXXX|,
        $args{caller} || ( split m{/}, ( caller )[1])[-1],
        $args{nick} || q|void|;
    my $fh;
    ( $fh, $fn ) = tempfile $fn,
      DIR => $args{dir} || cwd, SUFFIX => $args{suffix} || '';
    push @Tempfiles, $fn;
    print $fh $args{content}                                if $args{content};
    unlink $fn or croak qq|[unlink] ($fn): $!|               if $args{unlink};
    return $fn            }

END { unlink @Tempfiles if $$ == shift @Tempfiles }

=item B<FAFTS_tempdir()>

    use t::TestSuite qw/ :temp /;
    $tempdir = FAFTS_tempdir %args;

Creates a temporal directory.
This directory is scheduled for deletion when test-unit completes.
The directory is named:
F<skip_$caller_$nick_XXXX>.
Known parameters are:

=over

=item I<$caller>

If unset, reasonable default based on B<caller> return is provided.

=item I<$dir>

Overrides default provided by B<File::Temp::tempdir()>.

=item I<$nick>

Arbitrary identification what has meaning in callig code.
C<void> isa default.

=item I<$suffix>

Obvious.

=back

Returns dirname.
If I<$args{dir}> is set, then dirname is expanded to be fully qualified;
no canonicalization.

=cut

sub FAFTS_tempdir ( % ) {
    my %args = @_;
    my $dn = sprintf q|skip_%s_%s_XXXX|,
      $args{caller} || ( split m{/}, ( caller )[1])[-1],
      $args{nick} || q|void|;
    $dn = tempdir $dn,
      DIR => $args{dir}, SUFFIX => $args{suffix}, CLEANUP => 1;
    $dn = sprintf q|%s/%s|, cwd, $dn                        unless $args{dir};
    return $dn           }

=item B<FAFTS_cat_fn()>

    use t::TestSuite qw/ :temp /;
    $new_file = FAFTS_cat_fn $new_dir, $old_file;

A helper routine.
Assists with a target filename preparation.
Returns a basename of I<$old_file> concatenated with I<$new_dir>.
B<(note)> Stolen from DFS (should've been done years ago).

=cut

sub FAFTS_cat_fn ( $$ ) { sprintf q|%s/%s|, shift, ( split m{/}, shift )[-1] }

=item B<FAFTS_get_file()>

    use t::TestSuite qw/ :file /;
    $content = FAFTS_get_file $filename;

Simple file content retriever.
Whatever has been retrieved is passed to L</B<FAFTS_diag()>>.

=cut

sub FAFTS_get_file ( $ ) {
    my $fn = shift @_;
    open my $fho, q|<|, $fn                  or croak qq|[open]{r} ($fn): $!|;
    read $fho, my $buf, -s $fho;
    FAFTS_diag $buf;
    open $fho, q|>|, $fn                     or croak qq|[open]{w} ($fn): $!|;
                     $buf }

=item B<FAFTS_set_file()>

    use t::TestSuite qw/ :file /;
    FAFTS_set_file $filename, $content;

Simple file content setter.
I<filename> is set to I<$content>.
Returns a size I<filename> gets
(pretty useles, for simmetry reasons).
If B<open> fails then B<croaks>.

=cut

sub FAFTS_set_file ( $$ ) {
    my( $fn, $content ) = @_;
    open my $fh, q|>|, $fn                      or croak qq|[open] ($fn): $!|;
    print $fh $content;
                    -s $fh }

=item B<FAFTS_append_file()>

    use t::TestSuite qw/ :file /;
    FAFTS_append_file $filename, $content;

Simple file content appender.
I<content> is appended to I<filename>.
Returns a size I<filename> gets
(pretty useles, but whatever).
If B<open> fails then B<croaks>.

=cut

sub FAFTS_append_file ( $$ ) {
    my( $fn, $content ) = @_;
    open my $fh, q|>>|, $fn                     or croak qq|[open] ($fn): $!|;
    print $fh $content;
                       -s $fh }

=back

=cut

=head1 METHODS AND WRAPPERS

=over

=cut

=item B<FAFTS_prepare_method()>

    use t::TestSuite qw/ :mthd /;
    $method = FAFTS_prepare_method
      $method_path, $method_name, $stderr_name, @cmds;

Simple method preparation wrapper.
I<method_path> is path where to store prepared wanabe method;
I<method_name> is basename of method template, it's supposed to be in F<./t/>
directory of distribution.
I<stderr_name> is path where I<STDERR> of wanabe method will be redirected
(it'll be stuck at the end of wanabe method)
(defaults to F</dev/null>).
I<@cmds> are commands that will be stuck at the end of wanabe method, just
after I<stderr_name>
(they might be ignored by method itself unless supported).
Returns basename of I<method_path> (courtesy);
that basename can be passed to B<F::AF::init()>
(proper configuration through I<$F::AF::CD{lib_method}> provided).

=cut

sub FAFTS_prepare_method ( $$$@ ) {
    my( $fh, $method, $stderr, @cmds ) = ( @_ );
    $stderr ||= q|/dev/null|;
# XXX:201403151708:whynot: Can't use B<FAFTS_get_file()> because it will B<diag()> retrieved.  And it's not going to change.
    open my $fhi, q|<|, qq|t/$method|;
    read $fhi, my $buf, -s $fhi;
    FAFTS_set_file $fh, <<END_OF_METHOD . join '', map qq|$_\n|, @cmds;
$buf;

__DATA__
$stderr
END_OF_METHOD
    chmod 0755, $fh                            or croak qq|[chmod] ($fh): $!|;
           ( split m{/}, $fh )[-1] }

=item B<FAFTS_wrap()>

    use t::TestSuite qw/ :mthd /;
    ( $rv, $stderr, $stdout ) = FAFTS_wrap { die q|gotch ya| };

Safety wrapper around code that could B<die> or B<fork>-and-B<die>.
Returns whatever I<code>.
If I<code> fails, then I<$@> is returned.
In list context also returns whatever has been printed
on I<STDERR> and I<STDOUT>.
In either case I<STDERR> and I<STDOUT> are passed to L</B<FAFTS_diag()>>.

=cut

my $root_pid = $$;
sub FAFTS_wrap ( & )                           {
    require POSIX                              or die q|<POSIX> is missing\n|;
    my $code = shift;
    my $stderr = FAFTS_tempfile nick => q|stderr|;
    open my $bckerr, q|>&|, \*STDERR     or croak qq|push [dup] (STDERR): $!|;
    my $stdout = FAFTS_tempfile nick => q|stdout|;
    open my $bckout, q|>&|, \*STDOUT     or croak qq|push [dup] (STDOUT): $!|;

    open STDERR, q|>|, $stderr;
    open STDOUT, q|>|, $stdout;
    my( $rv, $ee );
    eval { $rv = $code->(); 1 }                                   or $ee = $@;
    $$ != $root_pid                                 and POSIX::_exit( !!$ee );
    open STDERR, q|>&|, $bckerr           or croak qq|pop [dup] (STDERR): $!|;
    open STDOUT, q|>&|, $bckout           or croak qq|pop [dup] (STDOUT): $!|;

    $rv = $ee                                              unless defined $rv;
    FAFTS_diag !defined $rv                    ?           q|RV: (undef)| :
      ref $rv && $rv->isa( q|File::AptFetch| ) ? qq|method: ($rv->{pid})| :
                                                            qq|RV: ($rv)|;
    $stderr = FAFTS_get_file $stderr;
    $stdout = FAFTS_get_file $stdout;
    wantarray ? ( $rv, $stderr, $stdout ) : $rv }

=item B<FAFTS_wait_and_gain()>

    use t::TestSuite qw/ :mthd /;
    ( $rv, $stderr ) = FAFTS_wait_and_gain;

Very special wrapper for B<File::AptFetch::gain()>.
Waits ~10sec until any activity happens on a method side.
Then returns whatever B<F::AF::gain()> has returned
(RV is also passed to B<FAFTS_diag()>).
In list context collected I<STDERR> is returned too.

=cut

sub FAFTS_wait_and_gain ( $;$ )       {
    my $eng = shift @_;
# XXX:201402232036:whynot: Probably fixes this: http://www.cpantesters.org/cpan/report/b9de484c-9594-11e3-ae04-8631d666d1b8
    my $timeout = shift @_ || 20;
    my( $rc, $stderr );
    my $mark = $eng->{message};
    while( 0 < $timeout-- ) {
        my $serr;
        ( $rc, $serr ) = FAFTS_wrap { $eng->gain };
        $stderr .= $serr;
        (!$mark && $eng->{message}) ||
          $mark != $eng->{message}  ||
          $rc                                                        and last;
        sleep 1          }
    FAFTS_diag $rc;
    wantarray ? ( $rc, $stderr ) : $rc }

=back

=cut

=head1 DISCOVERY

=over

=cut

=item B<FAFTS_discover_lib()>

    $lib = t::TestSuite::FAFTS_discover_lib;
    defined $lib or die "not a *nix";
    $lib eq '' or die "not a debian";

Utility routine.
Discovers a place where methods are located.
Returns:

=over

=item *

Value of I<$lib_method> of B<File::AptFetch::ConfigData>, if preset.

=item *

C<undef>, if not a *nix, or I<@$config_source> of B<F::AF::CD> isn't set or
isn't ARRAY.

=item *

Empty line, if I<$config_source[0]> of B<F::AF::CD> isn't executable or
pipe-open failed, or wanabe I<$lib_method> stays FALSE.

=item *

whatever value of I<Dir::Bin::methods> parameter has been found.

=back

Also, unconditionally resets every imaginable locale-wise key in I<%ENV>.

=cut

sub FAFTS_discover_lib ( ) {
    -e q|/dev/null| && -r _ && -w _                           or return undef;
    my $lib = File::AptFetch::ConfigData->config( q|lib_method| );
    $lib                                                      and return $lib;
    my $aptconfig = File::AptFetch::ConfigData->config( q|config_source| );
    $aptconfig && ref $aptconfig eq q|ARRAY|                  or return undef;
    -x $aptconfig->[0]                                           or return '';
# XXX:201402201914:whynot: Balance:  point to change for everything in TS just before it actually makes any sense.
# FIXME:201402201918:whynot: B<locale(7)> and B<locale(5)> disagree.
# http://www.cpantesters.org/cpan/report/6da4431e-9305-11e3-b08a-33eef1eb6092
    $ENV{$_} = q|POSIX|                                                foreach
  qw| LC_CTYPE LC_COLLATE LC_TIME LC_NUMERIC LC_MONETARY LC_MESSAGES
      LC_PAPER   LC_NAME   LC_ADDRESS   LC_TELEPHONE  LC_MEASUREMENT
      LC_IDENTIFICATION         LC_ALL         LANG         LANGUAGE |;
# FIXME:201704081651:whynot: Disabling apt(8) for good.  JK abandoning.
                                                                    return '';
    my $pid = open my $fh, q{-|}, @$aptconfig                    or return '';
    while( my $line = <$fh> ) {
        $line =~ m{^Dir::Bin::methods\s+"(.+)";$}                     or next;
        $lib = $1;        last }
    undef                                                      while( <$fh> );
    close $fh                  or die qq|[apt-config]: close failed: $! ($?)|;
    waitpid $pid, 0;
# XXX:20090509002544:whynot: What if I<$lib> is C<0>?
                 $lib || '' }

=item B<FAFTS_discover_config()>

    $TSConfig = t::TestSuite::FAFTS_discover_config;
    defined $TSConfig or plan skip_all => 'no YAML';
    $TSConfig or plan skip_all => 'no config';
    $TSConfig = $TSConfig->{some_section};
    $TSConfig or plan skip_all => 'not configured';
    $TSConfig->{block} or plan skip_all => 'forbidden';

Simple TS configuration retriever.
Returns:

=over

=item *

If no YAML is found then returns C<undef>.

=item *

If no config is found then returns empty string.

=item *

Otherwise HASH.

=back

Filename is hard-coded to be F<ts-config.yaml> in distribution directory.
It's YAML.
It's supposed to have sections
(those are documented in units themselves).
I<{block}> (with negative meaning!) is supposed but otherwise not enforced.

=cut

sub FAFTS_discover_config ( )                                 {
    my $config;
    foreach my $lib ( qw| YAML::Syck YAML::XS YAML::Tiny YAML | ) {
        eval qq|require $lib|                                         or next;
        FAFTS_diag qq|[FAFTS_discover_config]: going with {$lib}|;
        $config = $lib;                                       last }
    $config                                                   or return undef;
    my $cfn = q|ts-config.yaml|;
    -f $cfn                                                      or return '';
    $config = 
      $config eq q|YAML::Syck| ? YAML::Syck::LoadFile( $cfn ) :
      $config eq q|YAML::XS|   ?   YAML::XS::LoadFile( $cfn ) :
      $config eq q|YAML::Tiny|   ?   YAML::Tiny->read( $cfn ) :
      $config eq q|YAML|       ?       YAML::LoadFile( $cfn ) :
                                            croak q|yaml-fsck| }

=back

=cut

1
