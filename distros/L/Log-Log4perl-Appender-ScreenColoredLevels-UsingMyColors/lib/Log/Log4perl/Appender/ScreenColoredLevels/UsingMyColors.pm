package Log::Log4perl::Appender::ScreenColoredLevels::UsingMyColors;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

$VERSION = '0.111';

use Term::ANSIColor qw(:constants color colored);
use Log::Log4perl::Level;

=encoding utf8

=head1 NAME

Log::Log4perl::Appender::ScreenColoredLevels::UsingMyColors - Colorize messages according to level amd my colors

=head1 SYNOPSIS

	use Log::Log4perl::Appender::ScreenColoredLevels::UsingMyColors;

=head1 SYNOPSIS

    use Log::Log4perl qw(:easy);

    Log::Log4perl->init(\ <<'EOT');
		log4perl.category = DEBUG, Screen
		log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels::UsingMyColors
		log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
		log4perl.appender.Screen.layout.ConversionPattern = [%p] %d %F{1} %L> %m %n
		log4perl.appender.Screen.color.trace = cyan
		log4perl.appender.Screen.color.debug = default
		log4perl.appender.Screen.color.info  = green
		log4perl.appender.Screen.color.warn  = default
		log4perl.appender.Screen.color.error = default
		log4perl.appender.Screen.color.fatal = red
    EOT


=head1 DESCRIPTION

=over 4

=item new

=cut

sub new {
    my( $class, @options ) = @_;

	#print STDERR "Options are ", Dumper( \@options ), "\n";

    my $self = {
        name   => "unknown name",
        stderr => 1,

        @options,
    	};

	my %trace_color;

	@trace_color{ qw(trace debug info error warn fatal) } = ( '' ) x 6;

	my %Allowed = map { $_, 1 } @{ $Term::ANSIColor::EXPORT_TAGS{constants} };

	foreach my $level ( qw( trace debug info error warn fatal) ) {
		next unless exists $self->{color}{$level};
		next if lc $self->{color}{$level} eq 'default';

		my @b = map { uc } split /\s+/, $self->{color}{$level};

		foreach my $b ( @b ) {
			die "Illegal color $b" unless exists $Allowed{ $b };
			}

		$trace_color{ $level } = $self->{color}{$level};
		}

	$self->{trace_color} = \%trace_color;

    bless $self, $class;
	}

 sub _trace_color {
 	my( $self, $level ) = @_;

 	$self->{trace_color}{ lc $level } || '';
 	}

=item log

=cut

BEGIN { $Term::ANSIColor::EACHLINE = "\n" };

sub log {
    my( $self, %params ) = @_;
	no strict 'refs';

    print { $self->{stderr} ? *STDERR : select }
    	colored(
        	$params{message},
    		$self->_trace_color( $params{log4p_level} )
    		);

	}

=back

=head1 DESCRIPTION

This appender acts like Log::Log4perl::Appender::ScreenColoredLevels, but
you get to choose the colors. You can choose any of the constants from
Term::ANSIColor.

=head1 TO DO


=head1 SEE ALSO

L<Log::Log4perl::Appender::ScreenColoredLevels>, L<Term::ANSIColor>

=head1 SOURCE AVAILABILITY

This source is on GitHub:

	https://github.com/briandfoy/log-log4perl-appender-screencoloredlevels-usingmycolors

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
