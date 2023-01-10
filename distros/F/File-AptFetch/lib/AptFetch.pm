# $Id: AptFetch.pm 562 2023-01-07 23:31:53Z whynot $
# Copyright 2009, 2010, 2014, 2017, 2023 Eric Pozharski <whynot@pozharski.name>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use warnings;
use strict;

package File::AptFetch;
use version 0.77; our $VERSION = version->declare( v0.1.15 );

use File::AptFetch::ConfigData;
use Carp;
use IO::Pipe;

=head1 NAME

File::AptFetch - perl interface onto APT-Methods

=head1 SYNOPSIS

    use File::AptFetch::Simple; # No, seriously.

=head1 DESCRIPTION

Shortly:

=over

=item *

Methods are usual executables.
Hence B<F:AF> forks.

=item *

There's no command-line interface for methods.
The IPC is two pipes (I<STDIN> and I<STDOUT> from method's POV).

=item *

Each portion of communication (named B<message>) consists of numerical code
with explaining text and a sequence of colon (C<':'>) separated lines.
A message is terminated with empty line.

=item *

L<File::AptFetch::Cookbook> has more.

=back

I<(disclaimer)>
Right now, B<F::AF> is in "proof-of-concept" state.
It surely works with local methods (F<file> and F<copy>);
I hope it will work with trivial cases of remote methods
(I<v0.1.9> I've left to hope, it totally does;
no manual interaction (credentials and/or tray closing) provided).
(B<F::AF> has no means to accept (not talking about to pass along)
authentication credentials;
So if your upstream needs authentication, B<F::AF> is of no help here.)
And one more warning:
you're supposed to do all the dirty work of managing --
B<F::AF> is only for comunication.
Hopefully, there will be someday a kind of super-module what would simplify all
this.

I<(warning)>
You should understand one potential tension with B<F::AF>:
B<wget(1)>, B<curl(1)>, various FTP clients, or whatever else that constitutes
B<fetcher> are (I hope so) thoroughly tested against monkey-wrench on the other
side of connection.
APT methods are B<not>.
APT talks to repositories;
those repositories are mostly mirrors.
Administrators of mirrors and mirror-net roots have at least a basic clue.
Pending discovery of APT methods behaviour when they face idiots on the other
side of connection.

There's a list of known bugs, caveats, and deficiencies.

=over

=item *

(I<v0.1.9>)
There were some concerns about signals.
Surprisingly, they're gone now.
The only corner left to try is a child ignoring signals at all
(stuck in syscall?).

=item *

That seems that upon normal operation there're no zombies left.
However, I'm not sure if B<waitpid> would work as expected.
(What if some method would take lots of time to die after being signaled?)

=item *

Methods are supposed (or not?) to write extra diagnostic at its I<STDERR>.
It stays the same as of your process.
However, I still haven't seen any output.
So, (first) I (and you) have nothing to worry about
and (second) I have nothing to work with.
That's possible that issue will stay as caveat.

=item *

I<@$log> is fragile.
Don't touch it.
However, there's a possibility of I<@$log> corruption, like this.
If method goes insane and outputs unparsable messages, then L</gain()> will
give
up immedately leaving I<@$log> unempty.
In that case you're supposed to recreate B<F::AF> object (or give up).
If you don't then strange things can happen (mostly -- give-ups again).
So, please, do.

=item *

I<@$diag> grows.
In next release there will be some means to maintain that.
Right now, clean I<@$diag> yourself, if that becomes an issue.

=item *

You're supposed to maintain a balance of requests and fetches.
If you try L</gain()> when there's no unfinished requests,
then method will timeout.
There's nothing to worry about actually except hanging for 120sec.

=back

B<(note)>
Documentation of this library must maintain 4 namespaces:

=over

=item Function/method parameter list (I<@_>)

Within a section they always refer to parameter names and keys
(if I<@_> is hash)
mentioned in nearest synopsis.

=item Explicit values in descriptive codes

They always refer to some value in nearest code.
C<$method>, C<$?> etc means that
there would be some value that has some relation with named something.
POD markup in descriptions means exactly that.

=item Keys of B<File::AptFetch> B<bless>ed object

Whatever missing in nearest synopsis fits here.
Each key has explicit content dereference attached.
So I<@$log> means that key named C<log> has value of C<ARRAY> reference,
I<%$message> has value of C<HASH> reference,
and I<$status> has value of plain scalar
(it's not reference to C<SCALAR>, or it would be I<$$status>).

=item Keys of B<File::AptFetch::ConfigData> configuration module

Within each section upon introducing they are explicitly mentioned as such.
The above explanation about explicit dereference applies here too.

=back

B<(note)>
B<Message headers> are refered as keys of some fake global I<%$message>.
So C<Filename> becomes I<$message{filename}>,
and C<Last-Modified> -- I<$message{last_modified}>.
I hope it's clear from context is that B<header> down- or up-stream.

B<(note)> Through out this POD "log item" means one line in I<@$log>;
"log entry" means sequence of log items including terminating empty item.

B<(note)>
Through out this POD "120sec timeout" means: "I<$timeout> in
B<File::AptFetch::ConfigData> being left as set in stock distribution,
overriden while pre-build configuring, or set at run-time".

=head1 IMPORTANT NOTE ON B<PERL-5.10.0>

It's neither bug nor caveat.
And it's out of my hands, really.
B<perl-5.10.0> exits application code differently if compared with
B<perl-5.10.1> (unbelievable?).
My understanding is that B<v5.10.0> closes handles first, then B<DESTROY>s.
Sometimes that filehandle closing happens in right order.
But most probably application is killed with I<$SIG{CHLD}>.
B<END{}> doesn't help --- that filehandle masacre happens before those blocks
are run.
I believe, whatever tinkering with the global I<$SIG{CHLD}> is a bad idea.
And terminating every method just after transfers have finished is same
stupid.
Thus, if you run B<perl-5.10.0> (probably any earlier too) destroy the
B<File::AptFetch> object explicitly before B<exit>ing app, if you care about
to be not I<$SIG{CHLD}>ed.

B<(note)>
Some believe that since I<v0.1.11> it ain't no issue anymore.

=head1 IMPORTANT NOTE ON B<LINUX>

Your script (or, more probably, one-liner) could exit with I<$CHILD_ERROR>
equal to I<$SIG{TERM}> (or whatever signal was configured
(I<$F::AF::ConfigData{signal}>).
It would look like your script was B<kill>ed.
It's not.
I've strace'd, I don't see an incoming signal.

My understanding is that B<fork> of linux is too thready.
Then when an object (it has to be global) is B<DESTROY>ed a method (what is a
child) indeed is B<kill>ed.
And it's I<$CHILD_ERROR> somehow propagates up to the parent.
However that propagation isn't reliable;
in some combinations of kernel, libc, and/or perl
and (that's important) *your* code probability of propagation reaches to ~1;
for other combinations it goes down to ~0.
E.g. comparse these, the only diffence is size of I<nvtype>:
L<C<double>|http://www.cpantesters.org/cpan/report/a747458a-03c1-11e4-99f1-ef7f0a370852>
and
L<C<long double>|http://www.cpantesters.org/cpan/report/ecc8ed5a-0666-11e4-a7dd-06790a370852>,
version of B<ExtUtils::MakeMaker> and definition of I<$ENV{LANG}>.
But there're failures with I<nvtype=>C<long double> too.

If that's ever a problem you should apply a simple work-around:

    $faf = File::AptFetch->init( ... );
    ...
    undef $faf;
    $faf = '';

The last assignment is essential.
I don't suggest that B<DESTROY> would be optimized away;
it just sneaks into final destroy-everything phase then.
From what the propagation raises.

=head1 METHODS

=over

=cut

=item B<init()>

    ref( my $fetch = File::AptFetch->init( $method )) or die $fetch;

That's an initialization stuff.
APT-Methods are userspace executables, you know, hence it B<fork>s.
If B<fork> fails, then it dies.
If all preparations succeede, then it returns B<File::AptFetch> B<bless>ed
object;
Otherwise a string describing issue is returned.
Any diagnostic from B<fork>ed instance and, later, B<exec>ed I<$method> goes
through C<STDERR>.
(And see L</_cache_configuration()>.)

An idea behind this ridiculous construct is that someday, in some future, there
will be a lots of concurency.
Hence it's impossible to maintain one package-wide store for fail description.
All methods of B<File::AptFetch> return descriptive strings in case of errors.
B<init()> just follows them.

I<$method> is saved in same named key for reuse.

Give-up codes:

=over

=item ($method): (lib_method): neither preset nor found

I<$lib_method> (in B<File::AptFetch::ConfigData>) points to a directory where
APT-Methods reside.
Without that knowledge B<File::AptFetch> has nothing to do.
It's either picked from configuration (build-time) or from B<apt-config> output
(run-time) (in that order).
It wasn't found in either place -- fairly strange APT you have.

=item ($method) is unspecified

I<$method> is required argument,
so, please, provide.

=item ($method): ($?): died without handshake

Start-up configuration is essential.
If I<$method> disconnects early, than that makes a problem.
The exit code (no postprocessing at all) is provided in braces.

=item ($method): timeouted without handshake

I<$method> failed to configure within time frame provided.
(I<v.0.0.8>)
L</_read()> has more about timeouts.

=item ($method): ($Status): that's supposed to be (100 Capabilities)

As described in "APT Method Interface", Section 2.2, I<$method> starts with
S<C<'100 Capabilities'>> Status Code.
I<$method> didn't.
Thus that's not an APT-Method.
B<File::AptFetch> has given up.

=back

Yet refer to L</_parse_status_code()>, L</_parse_message()>, and
L</_cache_configuration()> -- those can emit their own give-up codes
(they are passed up immediately by B<init()> without postprocessing).

=cut

my @apt_config;

sub init {
    my $cls = shift @_;
    my $self = { };
    $self->{method} = shift @_          or return q|($method) is unspecified|;
    $self->{log} = [ ];
    $self->{trace} = { };
    $self->{timeout} = File::AptFetch::ConfigData->config( q|timeout| );
    $self->{tick} = File::AptFetch::ConfigData->config( q|tick| );
    $self->{leftover} = '';
    bless $self, $cls;
    my $rc;
    '' eq ($rc = $self->_cache_configuration)                   or return $rc;
    File::AptFetch::ConfigData->config( q|lib_method| )              or return
      qq|($self->{method}): (\$lib_method): neither preset nor found|;
    $self->{it} = IO::Pipe->new;
    $self->{me} = IO::Pipe->new;

    defined( $self->{pid} = fork )    or die qq|[fork] ($self->{method}): $!|;

    unless( $self->{pid} )                                       {
        $self->{me}->writer; $self->{me}->autoflush( 1 );
        $self->{it}->reader; $self->{it}->autoflush( 1 );
        open STDOUT, q|>&=|, $self->{me}->fileno                        or die
          qq|[dup] (STDOUT): $!|;
        open STDIN, q|<&=|, $self->{it}->fileno  or die qq|[dup] (STDIN): $!|;
        exec sprintf q|%s/%s|,
          File::AptFetch::ConfigData->config( q|lib_method| ),
          $self->{method} or die qq|[exec] ($self->{method}): $!| }

# XXX:201402081601:whynot: It's B<local> to B<init()>, right?
    local $SIG{PIPE} = q|IGNORE|;
    $self->{it}->writer; $self->{it}->autoflush( 1 );
    $self->{me}->reader; $self->{me}->autoflush( 1 );
    $self->{me}->blocking( 0 );
    $self->{diag} = [ ];

    $self->{it}->print( map qq|$_\n|, 
      q|601 Configuration|, map( qq|Config-Item: $_|, @apt_config ), '' );

    $rc = $self->_read;
    $self->{ALRM_error}           and return qq|($self->{method}): timeouted|;
    exists $self->{CHLD_error}                                      and return
      qq|($self->{method}): ($self->{CHLD_error}): died without handshake|;
    @{$self->{log}}                                                  or return
      qq|($self->{method}): timeouted without handshake|;

# XXX:201404072118:whynot: Is it possible that in case of C<tag+107c> that assignment (and next one) is, spontaneously, treated as num-eq;  What results in C<'' == ''> (with no warnings(sic!)) and then B<return> that C<>?
# XXX:201404072146:whynot: Or.  Is it possible that B<_parse_status_code()> (or B<_parse_message()>), spontaneously, returns spcial C<'' or 0>?
# XXX:201404072148:whynot: Or.  Is it B<_cache_configuration()>?
# http://www.cpantesters.org/cpan/report/a27fdb52-bce0-11e3-add5-ed1d4a243164
# because
# http://www.cpantesters.org/cpan/report/0f218626-bcc2-11e3-add5-ed1d4a243164
    if( '' ne ($rc = $self->_parse_status_code) )    {}
    elsif( $self->{Status} != 100               )    {
        $rc =
          qq|($self->{method}): ($self->{Status}): | .
          q|that's supposed to be (100 Capabilities)| }
    elsif( '' ne ($rc = $self->_parse_message)  )    {}
    else                                             {
        $rc = $self                                   }
      $rc }

=item B<DESTROY()>

    undef $fetch;
    # or leave the scope

Cleanups.
A method is B<kill>ed and B<waitpid>ed, pipes are explicitly closed.
I anything goes wrong then B<carp>s, for obvious reasons.
B<waitpid> is unconditional and isn't timeout protected.

The actual signal sent for I<$pid> is configured with I<$signal> in
B<File::AptFetch::ConfigData>.
However one can override (upon build time) or
explicitly set it to any desired name or number (upon runtime).
Refer to B<File::AptFetch::ConfigData> for details.

=cut

sub DESTROY                       {
    my $self = shift;
# http://www.cpantesters.org/cpan/report/f55f934e-e292-11e3-84c4-fc77f9652e90 - 3
# http://www.cpantesters.org/cpan/report/2b538b74-e25f-11e3-84c4-fc77f9652e90 - 1
# http://www.cpantesters.org/cpan/report/685fd35c-e196-11e3-84c4-fc77f9652e90 - 2
# http://www.cpantesters.org/cpan/report/150e44ca-e166-11e3-84c4-fc77f9652e90 - 3
# http://www.cpantesters.org/cpan/report/8eca3532-e100-11e3-84c4-fc77f9652e90 - 6
# http://www.cpantesters.org/cpan/report/97267764-e0cd-11e3-84c4-fc77f9652e90 - 1
# http://www.cpantesters.org/cpan/report/857323ca-dff9-11e3-84c4-fc77f9652e90 - 6
# http://www.cpantesters.org/cpan/report/cc12e132-df4d-11e3-84c4-fc77f9652e90 - 1
    local $SIG{PIPE} = q|IGNORE|;
    kill File::AptFetch::ConfigData->config( q|signal| ) => $self->{pid}    or
      carp qq|[kill] ($self->{pid}): nothing to kill or $!|   if $self->{pid};
    close $self->{me} or carp qq|[close] (reader): $!|         if $self->{me};
    close $self->{it} or carp qq|[close] (writer): $!|         if $self->{it};
    waitpid $self->{pid}, 0                                   if $self->{pid};
    delete @$self{qw| pid me it |} }

=item B<set_callback()>

    File::AptFetch::set_callback %callbacks;

(I<v0.1.6>)
Sets (whatever known) callbacks.
Semantics and procedures are documented where apropriate.
Keys of I<%callbacks> are tags
(subject to hash handling by perl, don't mess);
key must be among known (or else).
Values are either

=over

=item *

CODE -- whatever previous value was would be vanished;

=item *

C<undef> -- resets callback to default, if any;

=item *

anything else -- C<croak>.

=back

Known tags are:

=over

=item C<gain>

(I<v0.1.7>) L</B<gain()>> has more.

=item C<read>

L</B<_read()>> has more.

=item C<select>

(I<v0.1.8>) L</B<_read()>> has more.

=back

=cut

my( $_gain_callback, $_read_callback, $_select_callback );
sub set_callback ( % )                            {
    my %callbacks = @_;
    while( my( $tag, $code ) = each %callbacks ) {
        ref $code eq q|CODE| || !defined $code                        or croak
          qq|($tag): candidate to pass in is neither CODE nor (undef)|;
        if( $tag eq q|read| && $code )        {
            $_read_callback = $code            }
        elsif( $tag eq q|read|       )        {
            $_read_callback = \&_read_callback }
        elsif( $tag eq q|gain|       )        {
            $_gain_callback = $code            }
        elsif( $tag eq q|select|     )        {
            $_select_callback = $code          }
        else                                  {
            croak qq|($tag): unknown callback| }  }}

=item B<request()>

    my $rc = $fetch->request(
      $target0 => $source,
      $target1 => { uri => $source } );
    $rc and die $rc;

B<(bug)>
In that section abbreviation "URI" actually refers to "scheme-specific-part".
Beware.

That files requests for transfer.
Each request is a pair of I<$target> and either of

=over

=item I<$source>

Simple scalar;
It MUST NOT provide schema -- pure filename (either local or remote);
It MUST provide all (and no more than) needed leading slashes though
(double slash for remotes).

I<$source> is preprocessed -- I<$method> (with obvious colon) is prepended.
(That seems, APT's method become very nervous if being requested mismatching
method's name schema.)
B<(bug)> That requirement will be slightly relaxed in next release.

=item I<%$source> C<HASH> ref

Such keys are known

=over

=item I<$uri>

The same requirements as for I<$source> apply.

=back

There're other keys yet that must be supported.
Right now I unaware of any
(pending real-life testing).

=back

(I<v0.1.5>)
If request list is empty then silently succeeds without doing anything.

Actual request is filed at once (subject to buffering though),
in one big (or not so) chunk (as requested by API).
I<@$diag> field is updated accordingly.

Give-up codes:

=over

=item ($method): ($filename): URI is undefined

Either I<$source> or I<$source{uri}> was evaluated to FALSE.
(What request is supposed to be?)

B<(caveat)>  While C<undef> and empty string are invalid URIs,
is C<0> a valid URI?
No, URI is supposed to have at least one leading slash.

=back

B<request()> pretends to be atomic,
the request would happen only in case I<@_> has been parsed successfully.

=cut

sub request {
    my( $self, %request ) = @_;
    my $log;
    while( my( $filename, $source ) = each %request ) {
        my $uri = ref $source ? $source->{uri} : $source;
        $uri   or return qq|($self->{method}): ($filename): URI is undefined|;
        $uri = qq|$self->{method}:$uri|;
        $self->{trace}{$uri} = { filename => $filename };
        $log .= <<"END_OF_LOG"                         }
600 URI Acquire
URI: $uri
Filename: $filename

END_OF_LOG
    $log                                                         or return '';
    $self->{it}->print( $log );
    push @{$self->{diag}}, split( qr{\n}s, $log ), q||;
          '' }

=item B<gain()>

    $rc = $fetch->gain;
    $rc and die $rc;

That gains something.
'Something' means it's unknown what kind of message APT's method would return.
It can be S<'URI Start'>, S<'URI Done'>, or S<'URI Failure'> messages.
Anyway, message is stored in I<@$diag> and I<%$message> fields of object;
I<$Status> and I<$status> are set too.

Give-up codes:

=over

=item ($method): ($CHLD_error): died

Something gone wrong, the APT's method has died;
More diagnostic might gone onto I<STDERR>.
Even if I<$CHLD_error> is C<0> the method still died on us --
it's not supposed to exit.

=item ($method): timeouted without responce

The APT's method has quit without properly terminating message with empty line
or failed to output anything at all.
Supposedly, shouldn't happen.
Otherwise, that's your fault -- you asked for entry without reason.

=item ($method): timeouted

The APT's method has sat silently all the time.
The possible cause would be you've run out of requests
(than the method has nothing to do at all
(they don't tick after all)).

=back

L</_parse_status_code()> and L</_parse_message()> can emit their own give-up
codes.

Unless any problems just before B<return> C<gain> callback is tried (if any).
That CODE is given the object as an argument.
There's no default callback.
RV is ignored;
B<(note)> That might change in future, beter return TRUE.

=cut

sub gain {
    my $self = shift @_;

# XXX:201405110319:whynot: It looks excessive.  It's not.  There could be multiple unparsed entries.
    until( @{$self->{log}} && grep $_ eq '', @{$self->{log}} ) {
        $self->_read;
        $self->{ALRM_error}       and return qq|($self->{method}): timeouted|;
        exists $self->{CHLD_error}                                  and return
          qq|($self->{method}): ($self->{CHLD_error}): died|;
        @{$self->{log}}                                              or return
          qq|($self->{method}): timeouted without responce|     }

    my $rv = $self->_parse_status_code || $self->_parse_message;
    $_gain_callback->( $self )      if ref $_gain_callback eq q|CODE| && !$rv;
      $rv }

=item B<_parse_status_code()>

    $rc = $self->_parse_status_code;
    return $rc if $rc;

Internal.
Picks one item from I<@$log> and attempts to process it as a Status Code.
Consequent items are unaffected.

Give-up codes:

=over

=item ($method): ($log_item): that's not a Status Code

The $log_item must be C<qr/^\d{3}\s+.+/>.
No luck this time.

=back

Sets apropriate fields
(I<$Status> with the Status Code, I<$status> with the informational string),
then backups the processed item.

=cut

sub _parse_status_code {
    my $self = shift;
    $self->{log}[0] =~ m|^(\d{3})\s+(.+)|                            or return
      qq|($self->{method}): ($self->{log}[0]): that's not a Status Code|;
    @$self{qw| Status status |} = ( $1, $2 );
    push @{$self->{diag}}, shift @{$self->{log}};
                     '' }

=item B<_parse_message()>

    $rc = $self->_parse_message;
    return $rc if $rc;

Internal.
Processes the log entry.
Atomically sets either I<%$capabilities> (if I<$Status> is C<100>)
or I<%$message> (any other).
Each key is lowercased.
(I<v0.1.4>)
Since L</_read()> has been rewritten there could be multiple messages in
I<@$log>;
those are preserved for next turn.

(I<v0.1.2>)
Each hyphen (C<->) is replaced with an underscore (C<_>).
For convinience reasons
(compare S<C<< 'last-modified' => $time >>> with
S<C<< last_modified => $time >>>.)
B<(bug)>
What if a method yelds C<Foo-Bar:> and C<Foo_Bar:> headers?
(C<RFC2822> headers are anything but space and colon after all.)
Right now, B<_parse_message()> will fail if a message header gets reset.
But those headers are different and should be handled appropriately.
They aren't.

Give-up codes:

=over

=item ($method): ($log_item): message must be terminated by empty line

APT method API dictates that messages must be terminated by empty line.
This one is not.
Shouldn't happen.

=item ($method): ($log_item): that resets header ($header)

The leading message header (I<$header>) has been seen before.
That's a panic.
The offending and all consequent items are left on I<@$log>.
Shouldn't happen.

=item ($method): ($log_item): that's not a Message

The I<$log_item> must be C<< qr/^[0-9a-z-]+:(?>\s+).+/i >>.
It's not.
No luck this time.
The offending and all consequent items are left on I<@$log>.

=back

The I<$log_item>s are backed up and removed from I<@$log>.

B<(bug)> If the last item isn't an empty line,
then C<undef> will be pushed.
Beware and prevent before going for parsing.

=cut

sub _parse_message {
    my $self = shift;
    my %cache;
    while( @{$self->{log}} )                        {
        if( $self->{log}[0] eq '' ) {
            push @{$self->{diag}}, shift @{$self->{log}};
                                last }
        my( $header, $field ) =
          $self->{log}[0] =~ m{^([0-9a-z-]+):(?>\s+)(.+)}i           or return
          qq|($self->{method}): ($self->{log}[0]): that's not a Message|;
        $header =~ tr{A-Z-}{a-z_};
        exists $cache{$header}                                      and return
          qq|($self->{method}): ($self->{log}[0]): | .
                    qq|that resets header ($header)|;
        $cache{$header} = $field;
        push @{$self->{diag}}, shift @{$self->{log}} }
    $self->{diag}[-1] eq ''                                          or return
      qq|($self->{method}): ($self->{diag}[-1]): | .
       q|message must be terminated by empty line|;
    $self->{$self->{Status} == 100 ? q|capabilities| : q|message|} = \%cache;
                 '' }

=item B<_cache_configuration()>

    $rc = $self->_cache_configuration;
    return $rc if $rc;

Internal.
B<fork>s.
B<die>s if B<fork> fails.
B<fork>ed child B<exec>s an array set in I<@$config_source>
(from B<File::AptCache::ConfigData>).
If I<$ConfigData{lib_method}> is unset,
then parses prepared cache for I<Dir::Bin::methods>
item and (if finds) sets I<$lib_method>.
It doesn't complain if I<$lib_method> happens to be left unset.
If cache is set it B<return>s without any activity.

I<@$config_source> is subject to the build-time configuration.
It's preset with S<C<qw[ /usr/bin/apt-config dump ]>>
(YMMV, refer to B<F::AF::CD> to be sure).
I<@$config_source> must provide reasonable output -- that's the only
requirement
(look below for details).

B<(bug)>
While I<@$config_source> is configurable all give-up codes and
diagnostic messages refer
to C<'apt-config'>.

I<@$config_source>'s output is postprocessed --
configuration names and values are stored as equal (C<'='>) separated pairs in
scalars and pushed into intermediate array.
If everything finishes OK, then the package-wide cache is set.
That cache is lexical
(that's possible, I would find a reason to make some kind of iterator some time
later;
such iterator is missing right now).

(I<v0.1.2>)
Parsing cycle has suffered total rewrite.
First line is split on space into I<$name> and I<$value> (or else).
Then comes validation
(it woulnd't be needed if I<@{$ConfigData{config_source}}> would be
hardcoded, it's not):
* I<$name> must consist of alphanumerics, underscores, pluses, minuses,
dots, colons, and slashes (C<qr[\w/:.+-]>) (or else);
* (that's an heuristic) colons come in pairs (or else);
* I<$value> must be double-quote (C<">) enclosed, with no double-quote
inside allowed (or else);
* there must be terminating semicolon (C<;>) (or else).
Then comes cooking (all cooking is found by observation, it mimics APT-talk
with methods):
* trailing double pair-of-colons in I<$name> is trimmed to single pair;
* every space in I<$value> is percent escaped (C<%20>);
* every equal sign in I<$value> is percent escaped (C<%3d>).

That last one, needs some explanation.
B<apt.conf(5)> clearly states:
"Values must not include backslashes or extra quotation marks".

    apt-config dump | grep \\\\

disagrees on backslashes (if you're upgraded enough).
So does B<F::AF>: backslashes are passed through.
After some experiments double-quote handling looks, roughly, like this:
* double-quotes must come in pairs;
* those double-quotes are dropped from I<$value> withouth any visible effects
(double-quotes, not enclosed content;
it stays intact;
whatever content, empty string is content too);
* if there's any odd double-quote that fails parsing.
B<F::AF> doesn't need to do anything about it --
I<@{$ConfigData{config_source}}> is supposed to handle those itself.

B<(bug)>
What should be investigated:
* what if double-quote is explicitly percent-escaped in F<apt.conf>?
* how percents in I<$value> are handled?
Pending.

Give-up codes:

=over

=item ($method): ($line): that's unparsable

Validation (described above) has failed.

=item ($method): [close] (apt-config) failed: $!

After processing input a pipe is B<close>d.
That B<close> failed with I<$!>.

=item ($method): (apt-config): timeouted

While processing a fair 120sec timeout is given
(it's reset after each I<$line>).
I<@$config_source> hanged for that time.

=item ($method): (apt-config) died: ($?)

I<@$config_source> has exited uncleanly.
More diagnostic is supposed to be on I<STDERR>.

=item ($method): (apt-config): failed to output anything

I<@$config_source> has exited cleanly,
but failed to provide any output to parse at all.

=back

=cut

sub _cache_configuration {
    my $self = shift;
    @apt_config                                                 and return '';
    $self->{me} = IO::Pipe->new;
    
    defined( $self->{pid} = fork )  or die qq|[fork] (apt-config) failed: $!|;

    unless( $self->{pid} )     {
        $self->{me}->writer;
        $self->{me}->autoflush( 1 );
        open STDIN, q|<|, q|/dev/null|   or die qq|[open] (STDIN) failed: $!|;
        open STDOUT, q|>&=|, $self->{me}->fileno                        or die
          qq|[dup] (STDOUT) failed: $!|;
        exec @{File::AptFetch::ConfigData->config( q|config_source| )}  or die
          qq|[exec] (apt-config) failed: $!| }

    local $SIG{PIPE} = q|IGNORE|;
    $self->{me}->reader;
    $self->{me}->autoflush( 1 );

    $self->_read;
    $self->{me}->close                                               or return
      qq|($self->{method}): [close] (apt-config) failed: $!|;
# FIXME: Do I need it?
    delete @$self{qw| me it |};
# FIXME: Should timeout B<waitpid>.
    waitpid delete $self->{pid}, 0                            if $self->{pid};
    $self->{ALRM_error}                                             and return
      qq|($self->{method}): (apt-config): timeouted|;
# XXX:201405122039:whynot: I<$CHLD_error> is C<0> here.  But we don't care.
    $self->{CHLD_error}                                             and return
      qq|($self->{method}): (apt-config) died: ($self->{CHLD_error})|;
    @{$self->{log}}                                                  or return
      qq|($self->{method}): (apt-config): failed to output anything|;
    my @cache;
    while( my $line = shift @{$self->{log}} ) {
        my( $name, $value ) = split m{ }, $line, 2;
        $name !~ m{^[\w/:.+-]+$}          ||
        $name =~ m{(?<!:)(?:::)*:(?!:)}   ||
        !$value || $value !~ m{^"([^"]*)";$}                        and return
          qq|($self->{method}): ($line): that's unparsable|;
        ($value = $1) eq ''                                          and next;
        undef                                     while $name =~ s{::::$}{::};
        $value =~ s{ }{%20}g;
        $value =~ s{=}{%3d}g;
        push @cache, qq|$name=$value|          }
    unless( File::AptFetch::ConfigData->config( q|lib_method| )) {
        foreach my $rec ( @cache ) {
            $rec =~ m{^Dir::Bin::methods=(.+)$}                       or next;
            File::AptFetch::ConfigData->set_config( lib_method => $1 );
                               last }                             }
    delete $self->{CHLD_error};
    @apt_config = ( @cache );
# FIXME:201403151954:whynot: Otherwise I<@apt_config> would be returned.  That's not going to change.
                       '' }

=item B<_uncache_configuration()>

    File::AptFetch::_uncache_configuration;
    # or
    $self->_uncache_configuration;
    # or
    $fetch->_uncache_configuration;

Internal.
That cleans APT's configuration cache.
That doesn't trigger recacheing.
That cacheing would happen whenever that cache would be required again
(subject to the natural control flow).

B<(caveat)>
B<_cache_configuration> sets I<$lib_method> (in B<File::AptFetch::ConfigData>)
(if it happens to be undefined).
B<&_uncache_configuration> untouches it.

=cut

sub _uncache_configuration () { @apt_config = ( ) }

=item B<_read()>

    $fetch->_read;
    $fetch->{ALRM_error} and
      die "internal error: requesting read while there shouldn't be any";
    $fetch->{CHLD_error} and
      die "external error: method has gone nuts and AWOLed";

Internal.  Refactored.
That attempts to read the log entry.
Whatever has been read is split in items, B<chomp>ed, and B<push>ed onto
I<@$log>.
Now, item consuming will be finished if:

=over

=item empty-line separator has been found

(I<v0.1.9> there was major breakage at that point after I<v0.1.4>)
Somewhere in I<@$log> there's, at least one, empty-line separtor.
For technical reasons it doesn't have to be the last one.
For more confusion the last item might be unempty.
It's up to you would you consume everything in I<@$log>,
complete entries (with empty-line separtors), or
only first complete entry --
B<_read> doesn't care.
In either case, you may be sure if B<_read> returns clean (see below) there's
at least one compelte entry.

=item child has timeouted

If child timeouts, then I<$ALRM_error> is set
(to TRUE, otherwise meaningles).
Technically speaking a method just has nothing to say.
It's up to caller to decide what to do
(and it's caller's fault that there was attempt to get entry while there was
no reason to be any).
Anyway, I<$ALRM_error> is forced to be FALSE upon entering B<select> loop.

(I<v0.0.8>)
And more about what timeout is.
It was believed, that methods pulse their progress.
That belief was in vain.
Thus for now:

=over

=item *

The timeout is configurable through I<$ConfigData{timeout}>
(120sec, by stock configuration;
no defaults.)
The timeout is cached in each instance of B<File::AptFetch> object.

=item *

I<(v0.1.6)>
Target filenames are cached in the B<F::AF> object.
For each target there's a HASH.
In the HASH a key I<filename> is set to target filename value.

=item *

I<(v0.1.4)>
Timeout (the big one I<$timeout>) is made in supposedly small
I<$ConfigData{tick}>s
(5sec, by stock configuration;
no defaults.)
The small timeout is made with 4-arg B<select>.

=item *

I<(v0.1.6)>
If there's no input from method then routing is made as follows:

=over

=item +

Each target's cached HASH is passed to C<read> callback
(L</set_callback()> has more).

=item +

If any callback returns TRUE then resets timeout counter and
goes for next I<$tick> long B<select>
(IOW, file transfer (whatever that means) is in progress).

=item +

If every callbacks return FALSE then advances to timeout and
goes for next I<$tick> long B<select>.

=item +

I<(not implemented)>
If any callback returns C<undef> then fails entirely.

=back

=back

=item child has exited

The child is B<waitpid>ed and then I<$CHLD_error> is set.
It's possible that's normal for child to exit --
it's up to caller to decide.
Anyway, after child has exited there's nothing to B<read> from.

=item unknown error has happened

(I<v.0.1.4>)
It used to be read-with-alarm-in-eval.
It's not anymore, thus any B<signal(7)> will kill a process.
Then it dies.

=back

=cut

sub _read {
    my $self = shift;

    $self->{ALRM_error} = 0;
    my $timeout = $self->{timeout};
# XXX:202301072158:whynot: Otherwise unfinished line would be lost.  Still no proper testing.
    my $leftover = \$self->{leftover};
    while( 1 )                                                     {
        $timeout -= $self->{tick};
        my $vec = '';
        vec( $vec, $self->{me}->fileno, 1 ) = 1;
        $_select_callback->( $self )                     if $_select_callback;
        unless( select $vec, undef, undef, $self->{tick} )        {
            my $rc;
            $rc +=
              $_read_callback->( $_ ) || 0   foreach values %{$self->{trace}};
            if( $rc             ) {   $timeout = $self->{timeout} }
            elsif( $timeout < 0 ) { $self->{ALRM_error} = 1; last }}
        elsif( not defined( my $flag =
          $self->{me}->sysread( my $buffer, 4096 ))      )        {
                            die qq|[sysread] ($self->{method}) $!| }
        elsif( $flag                                     )        {
            $buffer = $$leftover . $buffer;
            my @prelog = split m{\n}, $buffer, -1;
# WORKAROUND:202301052252:whynot: If C<chop $buffer> is C<\n> then B<split()> spews in one more trailing empty string (that empty string will break fscking everything).
## XXX:202301062317:whynot: Correctness of log entry processing lacks explicit testing.  Sorry about that.
# XXX:202301070412:whynot: Here's the deal.  If C<chop $buffer> is C<\n> then surprise empty string resets I<$leftover>.  If C<chop> isn't then I<$leftover> is refilled.  Neat :)
            $$leftover = pop @prelog;
            push @{$self->{log}}, @prelog;
# WORKAROUND:201404232105:whynot: If method goes insane and bursts in one+ properly empty line separated messages then the separating empty line could got lost between.
# XXX:201404232106:whynot: That's F<t/v-method> what does it, AAMF.
# http://www.cpantesters.org/cpan/report/b19908e8-c870-11e3-aee5-9ca1c294a800
            grep $_ eq '', @prelog                        and last }
        elsif( !$flag                                    )        {
            waitpid delete $self->{pid}, 0;
            $self->{CHLD_error} = $?;                         last }
        else                                                      {
                                         die q|should not be here| }}

        '' }

=item B<_read_callback()>

I<(v0.1.6)>
Internal.
It's a default I<read> callback
(L</B<_read()>> has more).
It was supposed to be simple.
In vain.

The primary objective is avoiding false negatives at all cost.
Here comes list of avoided false negatives:

=over

=item *

Somewhere on C<lenny>/C<squeeze> time-span APT methods have changed behaviour.
In past they opened target for writing instantly.
Now they create a temporal and upon finishing rename it to target.
For obvious reasons methods do not communicate neither progress nor filename
of temporal.
If naming or handling of unfinished transfers would ever change there will be
breakage.

=item *

Then.
When transfer is finished *physically* it's not reported just yet
(temporal has been renamed).
A method calculates hashes.
For obvious reasons methods do not coummunicate progress either.
Naive approach would be to check size and then just wait forever.
That's possible size isn't known beforehand.
So B<_read_callback()> increases number of ticks before signaling timeout.
That increase is function of tick length (I<$ConfigData{tick}>), current file
size, and supposed IO speed.
The IO speed is hardcoded to be 15MB/sec.
So if media is realy slow (like a diskette or something) there's a possibility
of breakage.
However, those nitty-gritty manipulations won't result ever in timeout
decrease.

=back

For now it's not clear if B<_read_callback()> ought to provide some
diagnostics.
Right now it doesn't.

=cut

sub _read_callback   {
    my $st = shift;
    defined $st->{filename}                                   or return undef;
    $st->{tick} =
      File::AptFetch::ConfigData->config( q|tick| )        unless $st->{tick};
    $st->{flag} = 5                                unless defined $st->{flag};
    $st->{tmp} = ( glob qq|$st->{filename}*| )[0]   unless defined $st->{tmp};
    unless( defined $st->{tmp} )                                    {
# TODO:201403040310:whynot: Here comes diagnostics.
# warn sprintf qq|(%s) (%i): missing, ticks left\n|, ( split m{/}, $st->{filename} )[-1], $st->{flag} - 1
                                                                     }
    elsif( !-f $st->{tmp}      )                                    {
# TODO:201403040310:whynot: Here could be diagnostics too.
# warn sprintf qq|(%s): disappeared, forcing sync\n|, ( split m{/}, $st->{filename} )[-1];
        undef $st->{tmp}                                             }
    else                                                            {
        @$st{qw| size back |} = ( -s $st->{tmp}, $st->{size} || 0 );
        $st->{factor} = $st->{size} / ( $st->{tick} * 15 * 1024 * 1024 );
        $st->{factor} = 1                                if 1 > $st->{factor};
        $st->{flag} = 5 * $st->{factor} if $st->{size} - $st->{back} }
    0 < $st->{flag}-- }

set_callback read => \&_read_callback;

=back

=cut

=head1 DIAGNOSTICS

Most error communication is done through give-up codes.
However, some conditions aren't worth of keeping process alive -- those are
marked as B<(fatal)>.
Others are (mostly) in just B<fork>ed process that just couldn't boot
properly -- those are communicated back (somehow).

=over

=item (%s): candiate to pass is neither CODE nor (undef)

B<(fatal)>
In L</set_callback()>.
Tag C<%s> (may be unknown) tries to set something for callback.
That must be either CODE or C<undef>.
It's not.

=item (%s): unknown callback

B<(fatal)>
In L</set_callback()>.
Tag C<%s> is unknown.
Nothing to do with it but B<croak>.

=item [close] (reader): $!

In L</DESTROY()> (that's why it's not fatal).
Closing I<STDIN> of child has failed.
Nothing to do with it except blast ahead
(probably, would stuck in B<waitpid> then).

=item [close] (writer): $!

In L</DESTROY()> (that's why it's not fatal).
Closing I<STDOUT> of child has failed.
Nothing to do with it except blast ahead
(probably, would stuck in B<waitpid> then).

=item [dup] (STDIN): $!

In L</init()>.
Turning reader pipe into I<STDIN> has failed.
Parent will express it with S<($method): ($?): died without handshake> give-up
code.

=item [dup] (STDOUT): $!

In L</init()> or L</_cache_configuration()>.
Turning writer pipe into I<STDOUT> has failed.
Parent will express it with S<($method): ($?): died without handshake> or
S<($method): (apt-config) died: ($?)> give-up code.

=item [exec] ($method): $!

In L</init()>.
Executing requested I<$method> has failed.
Parent will express it with S<($method): ($?): died without handshake> give-up
code.

=item [fork] ($method): $!

=item [fork] (apt-config): $!

B<(fatal)>
In L</init()> (or L</_cache_configuration()> if talks about C<apt-config>).
B<fork> has failed.
Nothing can be done about it.

=item [kill] ($pid): nothing to kill or $!

In L</DESTROY()> (that's why it's not fatal).
Child has been reaped somehow already.
Probably OK for *nix of yours.

=item [open] (STDIN): failed: $!

In L</_cache_configuration()>.
Turning I<STDOUT> of upcoming I<$config_source>
(in B<File::AptFetch::ConfigData>) into F</dev/null> has failed.
Parent will express it with S<($method): (apt-config) died: ($?)> give-up
code.

=item should not be here at .../File/AptFetch.pm line %i

B<(fatal)>
In L</_read()>.
Per implementetaion there's a chain of if-elsif-else.
That B<else> covers a routes I haven't think of.
Purely my fault.

=item [sysread] ($method): $!

In L</_read()>.
That's what has happened -- B<sysread()> has failed for reasons.

=back

=head1 SEE ALSO

L<File::AptFetch::Cookbook>,
S<"APT Method Itnerface"> in B<libapt-pkg-doc> package,
B<apt-config(1)>,
B<apt.conf(5)>

=head1 AUTHOR

Eric Pozharski, <whynot@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2009, 2010, 2014 by Eric Pozharski

This library is free in sense: AS-IS, NO-WARANRTY, HOPE-TO-BE-USEFUL.
This library is released under GNU LGPLv3.

=cut

1;
