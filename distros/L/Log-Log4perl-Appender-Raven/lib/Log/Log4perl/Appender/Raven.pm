package Log::Log4perl::Appender::Raven;
$Log::Log4perl::Appender::Raven::VERSION = '0.006';
use Moose;

use Carp;
use Data::Dumper;
use Digest::MD5;
use Sentry::Raven;
use Log::Log4perl;
use Devel::StackTrace;
use Safe;
use Scope::Guard;
use Text::Template;

## Configuration
has 'sentry_dsn' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'sentry_timeout' => ( is => 'ro' , isa => 'Int' ,required => 1 , default => 1 );
has 'sentry_culprit_template' => ( is => 'ro', isa => 'Str', required => 1 , default => '{$function}');
has 'infect_die' => ( is => 'ro' , isa => 'Bool', default => 0 );
# STATIC CONTEXT
has 'context' => ( is => 'ro' , isa => 'HashRef', default => sub{ {}; });
# STATIC TAGS. They will go in the global context.
has 'tags' => ( is => 'ro' ,isa => 'HashRef', default => sub{ {}; });
# Log4Perl MDC key to look for tags
has 'mdc_tags' => ( is => 'ro' , isa => 'Maybe[Str]' , default => 'sentry_tags' );
# Log4perl MDC key to look for extra
has 'mdc_extra' => ( is => 'ro', isa => 'Maybe[Str]' , default => 'sentry_extra' );
# Log4perl MDC key to look for user data.
has 'mdc_user'  => ( is => 'ro' ,isa => 'Maybe[Str]' , default => 'sentry_user' );
# Log4perl MDC key to look for http data.
has 'mdc_http' => ( is => 'ro' , isa => 'Maybe[Str]' , default => 'sentry_http' );

## End of configuration

# Operation objects
has 'raven' => ( is => 'ro', isa => 'Sentry::Raven', lazy_build => 1);
has 'culprit_text_template' => ( is => 'ro', isa => 'Text::Template' , lazy_build => 1);
has 'safe' => ( is => 'ro' , isa => 'Safe', lazy_build => 1);


my %L4P2SENTRY = ('ALL' => 'info',
                  'TRACE' => 'debug',
                  'DEBUG' => 'debug',
                  'INFO' => 'info',
                  'WARN' => 'warning',
                  'ERROR' => 'error',
                  'FATAL' => 'fatal');

sub BUILD{
    my ($self) = @_;
    if( $self->infect_die() ){
        warn q|INFECTING SIG __DIE__ with Log4perl trickery. Ideally you should not count on that.

See perldoc Log::Log4perl::Appender::Raven, section 'CODE WIHTOUT LOG4PERL'

|;

        # Infect die. This is based on http://log4perl.sourceforge.net/releases/Log-Log4perl/docs/html/Log/Log4perl/FAQ.html#73200
        $SIG{__DIE__} = sub{

            ## Are we called from within log4perl at all.
            {
                my $frame_up = 0;
                while( my @caller = caller($frame_up++) ){
                    if( $caller[0] =~ /^Log::Log4perl/ ){
                        return;
                    }
                }
            }


            ## warn "CALLING die Handler";
            my $method = 'fatal';

            my $level_up = 1;

            # In an eval, nothing is fatal:
            if( $^S ){
                $method = 'error';
            }

            my ($package, $filename, $line,
                $subroutine, @discard )  = caller(0);
            # warn "CALLER PACKAGE IS $package\n";
            # warn "CALLER SUBROUTINE IS $subroutine";
            if( $package =~ /^Carp/ ){
                # One level up please. We dont want to make Carp the culprit.
                # and we want to know which is the calling package (to get the logger).
                ($package, @discard )  = caller(1);
                $level_up++  ;
            }

            my $logger = Log::Log4perl->get_logger($package || '');

            ## This will make sure the following error or
            ## fatal level work as usual.
            local $Log::Log4perl::caller_depth =
              $Log::Log4perl::caller_depth + $level_up ;

            $logger->$method(@_);

            if( $method eq 'error' ){
                # Do not die. This will be catched by the enclosing eval.
                return undef;
            }

            # Not in an eval, die for good.
            die @_;
        };
    }
}

sub _build_safe{
    # We do not authorize anything.
    return Safe->new();
}

{
    # The fallback culprint template will signal itself as such in sentry.
    my $FALLBACK_CULPRIT_TEMPLATE = 'FALLBACK {$function}';
    sub _build_culprit_text_template{
        my ($self) = @_;
        my $tmpl = Text::Template->new( TYPE => 'STRING',
                                        SOURCE => $self->sentry_culprit_template(),
                                    );
        unless( $tmpl->compile() ){
            warn "Cannot compile template from '".$self->sentry_culprit_template()."' ERROR:".$Text::Template::ERROR.
                " - Will fallback to hardcoded '".$FALLBACK_CULPRIT_TEMPLATE."'";
            $tmpl = Text::Template->new( TYPE => 'STRING', SOURCE => $FALLBACK_CULPRIT_TEMPLATE);
            $tmpl->compile() or die "Invalid fallback template ".$FALLBACK_CULPRIT_TEMPLATE;
        }
        return $tmpl;
    }
}

sub _build_raven{
    my ($self) = @_;

    my $dsn = $self->sentry_dsn || $ENV{SENTRY_DSN} || confess("No sentry_dsn config or SENTRY_DSN in ENV");


    my %raven_context = %{$self->context()};
    $raven_context{tags} = $self->tags();

    return Sentry::Raven->new( sentry_dsn => $dsn,
                               timeout => $self->sentry_timeout,
                               %raven_context
                             );
}

sub log{
    my ($self, %params) = @_;

    ## Any logging within this method will be discarded.
    if( Log::Log4perl::MDC->get(__PACKAGE__.'-reentrance') ){
        return;
    }
    Log::Log4perl::MDC->put(__PACKAGE__.'-reentrance', 1);

    # use Data::Dumper;
    # warn Dumper(\%params);

    # Look there to see what sentry expects:
    # http://sentry.readthedocs.org/en/latest/developer/client/index.html#building-the-json-packet

    my $sentry_message = length($params{message}) > 1000 ? substr($params{message}, 0 , 1000) : $params{message};
    my $sentry_logger  = $params{log4p_category};
    my $sentry_level = $L4P2SENTRY{$params{log4p_level}} || 'info';

    # We are 4 levels down after the standard Log4perl caller_depth
    my $caller_offset = Log::Log4perl::caller_depth_offset( $Log::Log4perl::caller_depth + 4 );

    ## Stringify arguments NOW (no_refs => 1). This avoids sending huuuuuge objects when
    ## Serializing this stack trace inside Sentry::Raven
    my $caller_frames = Devel::StackTrace->new( no_refs => 1);
    {
        ## Remove the frames from the Log4Perl layer.
        my @frames = $caller_frames->frames();
        splice(@frames, 0, $caller_offset);
        $caller_frames->frames(@frames);
    }

    my $call_depth = $caller_offset;

    # Defaults caller properties
    my $caller_properties = {
        function => 'main',
    };
    my @log_call_info = caller($call_depth - 1);
    $caller_properties->{line} = $log_call_info[2] || 'NOTOPLINE';

    {
        # Go up the caller ladder until the first non eval
        while( my @caller_info = caller($call_depth) ){

          # Skip evals and __ANON__ methods.
          # The anon method will make that compatible with the new Log::Any (>0.15)
          my $caller_string = $caller_info[3] || '';

          unless( ( $caller_string eq '(eval)' )
                  || ( scalar(reverse($caller_string)) =~ /^__NONA__/ )
                  #  ^ This test for the caller string to end with __ANON__ , but faster.
                ){
              # This is good.
              # Subroutine name, or filename, or just main
              $caller_properties->{function} = $caller_info[3] || $caller_info[1] || 'main';
              # For other properties, we are interested in the place where $log->something
              # was called, not were the caller of $log->something was called from
              my @log_call_info = caller($call_depth - 1);
              $caller_properties->{line} = $log_call_info[2] || 'NOLINE';
              last;
          }
          $call_depth++;
      }
    }

    my $tags = {};
    if( my $mdc_tags = $self->mdc_tags() ){
        $tags = Log::Log4perl::MDC->get($mdc_tags) || {};
    }

    my $extra = {};
    if( my $mdc_extra = $self->mdc_extra() ){
        $extra = Log::Log4perl::MDC->get($mdc_extra) || {};
    }

    my $user;
    if( my $mdc_user = $self->mdc_user() ){
        $user = Log::Log4perl::MDC->get($mdc_user);
    }

    my $http;
    if( my $mdc_http = $self->mdc_http() ){
        $http = Log::Log4perl::MDC->get($mdc_http);
    }


    # Calculate the culprit from the template
    my $sentry_culprit = do{
        #
        # See this. This is very horrible.
        # https://rt.cpan.org/Ticket/Display.html?id=112092
        #
        my %SIGNALS_BACKUP; my $guard;
        if( $Safe::VERSION >= 2.35 ){
            # We take a backup of the signals,
            # just because we know Safe will anihitate
            # them all :/
            %SIGNALS_BACKUP = %SIG;
            $guard = Scope::Guard::scope_guard(
                sub{
                    %SIG = %SIGNALS_BACKUP;
                });
        }
        $self->culprit_text_template->fill_in(
            SAFE => $self->safe(),
            HASH => {
                %{$caller_properties},
                message => $sentry_message,
                sign => sub{
                    my ($string, $offset, $length) = @_;
                    defined( $string ) || ( $string = '' );
                    defined( $offset ) || ( $offset = 0 );
                    defined( $length ) || ( $length = 4 );
                    return substr(Digest::MD5::md5_hex(substr($string, $offset, $length)), 0, 4);
                }
            });
    };

    # OK WE HAVE THE BASIC Sentry options.
    $self->raven->capture_message($sentry_message,
                                  logger => $sentry_logger,
                                  level => $sentry_level,
                                  culprit => $sentry_culprit,
                                  tags => $tags,
                                  extra => $extra,
                                  Sentry::Raven->stacktrace_context( $caller_frames ),
                                  ( $user ? Sentry::Raven->user_context(%$user) : () ),
                                  ( $http ? Sentry::Raven->request_context( ( delete $http->{url} ) , %$http ) : () )
                                 );

    Log::Log4perl::MDC->put(__PACKAGE__.'-reentrance', undef);
}


__PACKAGE__->meta->make_immutable();


=head1 NAME

  Log::Log4perl::Appender::Raven - Append log events to your Sentry account.

=head1 BUILD STATUS

=begin html

<a href="https://travis-ci.org/jeteve/l4p-appender-raven"><img src="https://travis-ci.org/jeteve/l4p-appender-raven.svg?branch=master"></a>

=end html

=head1 WARNING(s)

This appender will send ALL the log events it receives to your
Sentry DSN synchronously. If you generate a lot of logging, that can make your sentry account
saturate quite quickly and your application come to a severe slowdown.

Using Log4perl appender's Threshold or L<Log::Log4perl::Filter> in your log4perl config, and
experimenting a little bit is Highly Recommended.

Remember sentry is designed to record errors, so hopefully your application will
not generate too many of them.

You have been warned.

=head1 SYNOPSIS

Read the L<CONFIGURATION> section, then use Log4perl just as usual.

If you are not familiar with Log::Log4perl, please check L<Log::Log4perl>

In a nutshell, here's the minimul l4p config to output anything from ERROR to Sentry:

  log4perl.rootLogger=DEBUG, Raven

  log4perl.appender.Raven=Log::Log4perl::Appender::Raven
  log4perl.appender.Raven.Threshold=ERROR
  log4perl.appender.Raven.sentry_dsn="https://user:key@sentry-host.com/project_id"
  log4perl.appender.Raven.layout=Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Raven.layout.ConversionPattern=%X{chunk} %d %F{1} %L> %m %n


=head1 CONFIGURATION

This is just another L<Log::Log4perl::Appender>.

=head2 Simple Configuration

The only mandatory configuration key
is *sentry_dsn* which is your sentry dsn string obtained from your sentry account.
See http://www.getsentry.com/ and https://github.com/getsentry/sentry for more details.

Alternatively to setting this configuration key, you can set an environment variable SENTRY_DSN
with the same setting. - Not recommended -

Example:

  log4perl.rootLogger=ERROR, Raven

  layout_class=Log::Log4perl::Layout::PatternLayout
  layout_pattern=%X{chunk} %d %F{1} %L> %m %n

  log4perl.appender.Raven=Log::Log4perl::Appender::Raven
  log4perl.appender.Raven.sentry_dsn="http://user:key@host.com/project_id"
  log4perl.appender.Raven.sentry_timeout=1
  log4perl.appender.Raven.layout=${layout_class}
  log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}

=head2 Configuring the culprit string

By default, this appender will calculate the Sentry culprit to be
the fully qualified name of the function that called the log method, as Sentry
recommends.

If you require more flexibility and precision in your culprit, you can
configure it as a template. For instance:

  log4perl.appender.Raven.sentry_culprit_template={$function}-{$line}

The default is '{$function}', as Sentry prescribes. But most people will probably
be more happy with the added {$line} element, as it makes discriminating between culprits easier.

The template format follows L<Text::Template> and the available variables and functions are as follow:

=over

=item function

The fully qualified name of the function that called the log method.

=item line

The line at which the log method was called

=item message

The Log4perl generated message. Keep in mind that this is the message AFTER it has been calculated by
the layout pattern.

=item sign($string, $offset, $length)

A function that calculates a small (4 chars) signature of the given string. $string, $offset
and $length are optional.

This is useful for instance if some part of your code manage errors in a centralized way, or in other
terms if the place at which you call '$log->error()' can output various messages.
To help discriminating between culprit, you can for instance configure your culprit template:


  log4perl.appender.Raven.sentry_culprit_template={$function}-{$line}-{sign($message, 30, 4)}

Note that in the example, we look at a part of the message after the 30th character, which
helps skipping the common message parts defined by your message layout. Adjust this number (30)
to make sure you pick a substring of your message in a meaningful area.

=back

=head2 Timeout

The default timeout is 1 second. Feel free to bump it up. If sending an event
timesout (or if the sentry host is down or doesn't exist), a plain Perl
warning will be output.

=head2 Configuration with Static Tags

You have the option of predefining a set of tags that will be send to
your Sentry installation with every event. Remember Sentry tags have a name
and a value (they are not just 'labels').

Example:

  ...
  log4perl.appender.Raven.tags.application=myproduct
  log4perl.appender.Raven.tags.installation=live
  ...

=head2 Configure and use Dynamic Tagging

Dynamic tagging is performed using the Log4Perl MDC mechanism.
See L<Log::Log4perl::MDC> if you are not familiar with it.

Anywhere in your code.

  ...
  Log::Log4perl::MDC->set('sentry_tags' , { subsystem => 'my_subsystem', ... });
  $log->error("Something very wrong");
  ...

Or specify which key to capture in config:

   ...
   log4perl.appender.Raven.mdc_tags=my_sentry_tags
   ...


Note that tags added this way will be added to the statically define ones, or override them in case
of conflict.

Note: Tags are meant to categorize your Sentry events and will be displayed
in the Sentry GUI like any other category.

=head2 Configure and use User Data

Sentry supports structured user data that can be added to your event.
User data works a bit like the tags, except only three keys are supported:

id, username and email. See L<Sentry::Raven> (capture_user) for a description of those keys.


In your code:

  ...
  Log::Log4perl::MDC->set('sentry_user' , { id => '123' , email => 'jeteve@cpan.org', username => 'jeteve' });
  $log->error("Something very wrong");
  ...


Or specify the MDC key to capture in Config:

   ...
   log4perl.appender.Raven.mdc_user=my_sentry_user
   ...


=head2 Configure and use HTTP Request data.

Sentry support HTTP Request structured data that can be added to your event.
HTTP Data work a bit like tags, except only a number of keys are supported:

url, method, data, query_string, cookies, headers, env

See L<Sentry::Raven> (capture_request) or interface 'Http' in L<http://sentry.readthedocs.org/en/latest/developer/interfaces/index.html>
for a full description of those keys.

In your code:

  ...
  Log::Log4perl::MDC->set('sentry_http' , { url => 'http://www.example.com' , method => 'GET' , ... });
  $log->error("Something very wrong");
  ...

Or specify the MDC key to capture in Config:

  ...
  log4perl.appender.Raven.mdc_http=my_sentry_http
  ...

=head2 Configure and use Dynamic Extra

Sentry allows you to specify any data (as a Single level HashRef) that will be stored with the Event.

It's very similar to dynamic tags, except its not tags.

Then anywere in your code:

  ...
  Log::Log4perl::MDC->set('my_sentry_extra' , { session_id => ... , ...  });
  $log->error("Something very wrong");
  ...


Or specify MDC key to capture in config:

  ...
  log4perl.appender.Raven.mdc_extra=my_sentry_extra
  ...

=head2 Configuration with a Static Context.

You can use lines like:

  log4perl.appender.Raven.context.platform=myproduct

To define static L<Sentry::Raven> context. The list of context keys supported is not very
long, and most of them are defined dynamically when you use this package anyway.

See L<Sentry::Raven> for more details.

=head1 USING Log::Any

This is tested to work with Log::Any just the same way it works when you use Log4perl directly.

=head1 CODE WITHOUT LOG4PERL

Warning: Experimental feature.

If your code, or some of its dependencies is not using Log4perl, you might want
to consider infecting the __DIE__ pseudo signal with some amount of trickery to have die (and Carp::confess/croak)
calls go through log4perl.

This appender makes that easy for you, and provides the 'infect_die' configuration property
to do so:

  ...
  log4perl.appender.Raven.infect_die=1
  ...

This is heavily inspired by L<https://metacpan.org/pod/Log::Log4perl::FAQ#My-program-already-uses-warn-and-die-.-How-can-I-switch-to-Log4perl>

While this can be convenient to quickly implement this in a non-log4perl aware piece of software, you
are strongly encourage not to use this feature and pepper your call with appropriate Log4perl calls.

=head1 SEE ALSO

L<Sentry::Raven> , L<Log::Log4perl>, L<Log::Any> , L<Log::Any::Adapter::Log4perl>

=head1 AUTHOR

Jerome Eteve jeteve@cpan.com

=cut
