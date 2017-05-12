package Log::Log4perl::CommandLine;

use warnings;
use strict;

our $VERSION = '0.07';

use Log::Log4perl qw(get_logger :levels);
use Getopt::Long;

my %init;     # logconfig, loginit, logfile, logcategory, noinit
my %options;  # options set on command line

my %levelmap =
(
    q => 'off',
    quiet => 'off',
    v => 'info',
    verbose => 'info',
    d => 'debug'
);

sub import
{
    my $class = shift;

    my $caller = caller;

    my @getoptlist;
    my $next;
    foreach (@_)
    {
        if ($next)
        {
            $init{$next} = $_;
            $next = undef;
            next;
        }

        /^:(log(?:config|file|init|category))$/ and $next = $1; # Grab next arg

        /^(?:trace|:levels|:all)$/ and push(@getoptlist, 'trace:s@');
        /^(?:debug|:levels|:all)$/ and push(@getoptlist, 'debug:s@');
        /^(?:info|:levels|:all)$/  and push(@getoptlist, 'info:s@');
        /^(?:warn|:levels|:all)$/  and push(@getoptlist, 'warn:s@');
        /^(?:error|:levels|:all)$/ and push(@getoptlist, 'error:s@');
        /^(?:fatal|:levels|:all)$/ and push(@getoptlist, 'fatal:s@');
        /^(?:off|:levels|:all)$/   and push(@getoptlist, 'off:s@');

        /^(?:quiet|:long|:all)$/   and push(@getoptlist, 'quiet:s@');
        /^(?:verbose|:long|:all)$/ and push(@getoptlist, 'verbose:s@');

        /^(?:q|:short|:all)$/      and push(@getoptlist, 'q:s@');
        /^(?:v|:short|:all)$/      and push(@getoptlist, 'v:s@');
        /^(?:d|:short|:all)$/      and push(@getoptlist, 'd:s@');

        /^(?:loglevel|:logopts|:all)$/ and push(@getoptlist, 'loglevel:s@');

        /^(?:logconfig|:logopts|:all)$/ and
            push(@getoptlist, 'logconfig=s' => \$init{logconfig});

        /^(?:logfile|:logopts|:all)$/ and
            push(@getoptlist, 'logfile=s' => \$init{logfile});

        { no strict 'refs';
            /^handlelogoptions$/ and
                *{"$caller\::handlelogoptions"} = *handlelogoptions;
        }

        /^:noinit$/ and $init{noinit} = 1;
    }

    my $getopt = Getopt::Long::Parser->new
                 ( config => [qw(pass_through no_auto_abbrev
                                 no_ignore_case)] );

    $getopt->getoptions(\%options, @getoptlist);

    # Allow: --option --option foo --option foo,bar
    while (my ($opt, $cats) = each %options)
    {
        $options{$opt} = [ map { length $_ ? split(',') : '' } @$cats ];
    }

    # --loglevel category=level or --loglevel level
    foreach (@{$options{loglevel}})
    {
        my ($category, $level) = /^([^=]*?)=?([^=]+)$/;
        push(@{$options{$level}}, $category);
    }
    delete $options{loglevel};
}

INIT
{
    return if $init{noinit};

    if (defined $init{logconfig} and -f $init{logconfig} and -r _)
    {
        Log::Log4perl->init($init{logconfig});
    }
    else
    {
        if ($init{loginit} and not ref $init{loginit})
        {
            Log::Log4perl->init(\$init{loginit});
        }
        elsif ($init{loginit} and ref $init{loginit} eq 'ARRAY')
        {
            Log::Log4perl->easy_init(@{$init{loginit}});
        }
        else
        {
            my $init = ref $init{loginit} eq 'HASH' ? $init{loginit} : {};

            $init->{level} ||= $ERROR;
            $init->{layout} ||= '[%-5p] %m%n';

            Log::Log4perl->easy_init($init);
        }
    }

    handlelogoptions();
}

sub handlelogoptions
{
    if ($init{logfile})
    {
        my $logfile = $init{logfile};
        my $layout = '%d %c %m%n';

        if ($logfile =~ s/\|(.*)$//)   # "logfilename|logpattern"
        {
            $layout = $1;
        }

        my $file_appender = Log::Log4perl::Appender->new(
                                "Log::Log4perl::Appender::File",
                                name => 'logfile',
                                filename  => $logfile);

        $file_appender->layout(Log::Log4perl::Layout::PatternLayout->new(
                               $layout));

        get_logger('')->add_appender($file_appender);
    }

    while (my ($level, $vals) = each %options)
    {
        $level = $levelmap{$level} if exists $levelmap{$level};

        my $level_id = Log::Log4perl::Level::to_priority(uc $level);

        foreach my $category (@$vals)
        {
            if ($category eq '')
            {
                $category = defined($init{logcategory})
                            ? $init{logcategory}
                            : $level_id >= $INFO ? '' : 'main';
            }

            $category = '' if $category eq 'root';

            get_logger($category)->level($level_id);
        }
    }
}

1;

__END__

=head1 NAME

Log::Log4perl::CommandLine - Simple Command Line Interface for Log4perl

=head1 SYNOPSIS

 # Simple: just use the Module, with all the options

 use Log::Log4perl::CommandLine qw(:all);

 # Then run your program
 my_program.pl --verbose
 my_program.pl -v
 my_program.pl --debug
 my_program.pl -d
 my_program.pl --quiet
 my_program.pl -q

 # Flexible: include specific logging options:

 use Log::Log4perl::CommandLine qw(q v d);
 # or
 use Log::Log4perl::CommandLine qw(:short);

 use Log::Log4perl::CommandLine qw(quiet verbose);
 # or
 use Log::Log4perl::CommandLine qw(:long);

 use Log::Log4perl::CommandLine qw(trace debug info warn error fatal off);
 # or
 use Log::Log4perl::CommandLine qw(:levels);

 # q = quiet = off
 # v = verbose = info
 # d = debug

 my_program.pl --debug
 my_program.pl --debug MyModule
 my_program.pl --debug MyModule,MyOtherModule --debug Foo

 # Override configuration on command line:

 use Log::Log4perl::CommandLine qw(logconfig logfile loglevel);
 or
 use Log::Log4perl::CommandLine qw(:logopts);

 my_program.pl --logconfig /some/log4perl.conf

 my_program.pl --logfile /my/logfile.log

 my_program.pl --loglevel MyCat=debug   # equivalent to "-debug MyCat"
 my_program.pl --loglevel MyCat=mylevel # can use for custom log levels

 # Include simple Log4perl configurations:

 use Log::Log4perl::CommandLine qw(:logconfig /my/default/log4perl.conf);

 use Log::Log4perl::CommandLine qw(:logfile /my/default/logfile.log);

 # These match Log::Log4perl->easy_init():
 use Log::Log4perl qw(:levels);   # needed to define constants

 use Log::Log4perl::CommandLine ':loginit' => { level => $INFO };

 use Log::Log4perl::CommandLine ':loginit' => { layout => '%d %c %m%n' };

 use Log::Log4perl::CommandLine ':loginit' => { level => $WARN,
                                                layout => '%d %c %m%n' };

 use Log::Log4perl::CommandLine ':loginit' => [ { level => $WARN,
                                                  layout => '%d %c %m%n',
                                                  category => 'foo',
                                                  file => '>>foo.log' },
                                                { level => $DEBUG,
                                                  category => 'bar',
                                                  file => '>>bar.log' } ];

 # or inline a log4perl configuration:
 use Log::Log4perl::CommandLine ':loginit' => q(...some log4perl config...);

 # control which logger the unspecified levels affect:

 use Log::Log4perl::CommandLine qw(:logcategory root);
 # or
 use Log::Log4perl::CommandLine qw(:logcategory main);

 # if you don't specify :logcategory, levels INFO and higher => 'root',
 # and DEBUG and TRACE => 'main' (see below)

 # If you want to do your own initialization:
 use Log::Log4perl::CommandLine qw(:all :noinit);

 ... initialize Log4perl yourself...

 # Explicitly handle log command line options now
 Log::Log4perl::CommandLine::handlelogoptions();

 # Also call handlelogoptions() explicitly if you later redefine Log4perl

 # Export handlelogoptions() to caller's namespace
 use Log::Log4perl::CommandLine qw(handlelogoptions);
 handlelogoptions();

=head1 DESCRIPTION

C<Log::Log4perl::CommandLine> parses some command line options,
allowing for simple configuration of Log4perl using the command line,
or easy, temporary overriding of a more complicated Log4perl
configuration from a file.

If you want to use the constants ($ERROR, $INFO, etc.), you must C<use
Log::Log4perl>.

Any options parsed and understood by this module are stripped from
C<@ARGV> (by C<Getopt::Long>), so they won't interfere with later
command line parsing.

See L<Log::Log4perl::CommandLine::Cookbook> for examples of usage.

These enable command line options, parsed with L<Getopt::Long>, so you
can precede them on the command line with either '-' or '--'.

=head2 OPTIONS

=over

=item :short q v d

=item :long quiet verbose

=item :levels trace debug info warn error fatal off

On the C<use> line, you can explicitly specify just the options you
want, or the group (:short :long :levels) or :all to get them all.

q = quiet = off

v = verbose = info

d = debug

Each of these "level" options sets the logging level to the specified
level.  They each take an optional parameter with the category (or
categories) to apply the level to, or can be specified multiply.

e.g.
 --debug
 --debug MyCategory
 --debug Foo,Bar
 --debug Foo --debug Bar

If the optional parameter is not specified, the default behavior is to
apply the level to the root logger if the level is C<OFF>, C<FATAL>,
C<ERROR>, C<WARN> or C<INFO> and to the 'main' logger if the level is
C<DEBUG> or C<TRACE>.  This may seem a little weird, and it took me a
while to come to this default, but it fits the way I work best.

This means:
 my_program.pl -q or --quiet

suppresses warnings and errors in the whole logger hierarchy (unless
you've explicitly forced them through some other Log4perl setting) --
usually what I want quiet to mean.  Likewise, -v tells every module to
be a little more verbose.

 my_program.pl -d or --debug or --trace

however, just apply to the main program, so I don't get debugging
information from other modules I'm not working on.

You can also specifically refer to the root category with 'root':

 my_program.pl --trace root

If you don't like this behavior, you can explicitly define the
default log category with C<:logcategory E<lt>categoryE<gt>>

=item :logcategory <default category>

This is the category to use if one isn't specified in one of the level
options.

=item :logopts or loglevel

 --loglevel verbose
 --loglevel MyModule=debug
 --loglevel Foo=info,main=debug
 --loglevel foo=info --loglevel main=debug

This is just another way to set the level.  This can help avoid option
space pollution if you already use the standard options for other
purposes, or if you've defined special Log4perl levels beyond the
standard ones (but don't do that).

=item :logopts or logconfig

Enable C<--logconfig /my/log4perl.conf> to override the entire
Log4perl configuration.

=item :logopts or logfile

Enable C<--logfile /my/logfile.log> to create a log file.  You can
also append a special layout for the log file like this:

 my_program.pl --logfile '/my/logfile.log|%d %m%n'

Be sure to respect your shell's metacharacters and quote when needed.

=item :logconfig '/my/log4perl.conf'

Specify a Log4perl configuration file.  Contrary to normal Log4perl,
it is OK if the file is missing, things will just proceed with the
default configuration.

=item :logfile '/my/default/logfile.log'

Specify a default log file.  Similar to the --logfile option, you
can append a layout C<:logfile '/my/logfile.log|%d %m%n'>

=item :loginit { ...Log::Log4perl->easy_init() configuration... }

See basic examples in SYNOPSIS, Cookbook or L<Log::Log4perl> for more
details.

=item :loginit '... embedded Log4perl configuration ...'

See basic examples in Cookbook or L<Log::Log4perl> for more details.

=item :noinit

Disable all the automatic Log4perl initialization.  You must call
handlelogoptions() explicitly after you initialize Log4perl yourself.

:noinit is incompatible with the '--logconfig' command line option.

=item handlelogoptions

Exports the handlelogoptions() subroutine to the caller's namespace.
Call handlelogoptions() after re-initializing Log4perl to re-apply the
command line overrides.

=back

=head1 AUTHOR

Curt Tilmes, E<lt>ctilmes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Curt Tilmes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
