package Log::Dispatch::Prowl;
our $VERSION = '1.000';


use strict;
use warnings;

use WebService::Prowl;

use base qw( Log::Dispatch::Output );

use Params::Validate qw(validate SCALAR);
Params::Validate::validation_options(allow_extra => 1);

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = validate(
        @_,
        {   apikey => { type => SCALAR },
            name   => { type => SCALAR }, });

    my $self = bless { apikey => $p{apikey} }, $class;

    $self->_basic_init(%p);

    return $self;
}

my %map_level = (0 => -2, 1 => -2, 2 => -2, 3 => -1, 4 => 0, 5 => 1, 6 => 1, 7 => 2);

sub log_message {
    my $self = shift;
    my %p    = @_;

    my $ws = WebService::Prowl->new(apikey => $self->{apikey});

    my $level = $self->_level_as_number($p{level});
    my $event = uc($self->_level_as_name($p{level}));

    $ws->add(
        application => $p{name},
        event       => $event,
        priority    => $map_level{$level},
        description => $p{message});
}

1;

__END__

=head1 NAME

Log::Dispatch::Prowl - Object for logging to the iPhone

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log =
      Log::Dispatch->new
          ( outputs =>
            [ 'Prowl' =>
                  { min_level => 'debug',
                    name    => 'MyApp',
                    apikey => 'yourapicodehere',
                  },
            ],
          );

  $log->alert("I'm searching the city for sci-fi wasabi");

=head1 DESCRIPTION

This module provides an object for logging directly to your iPhone using
push notifications and the iPhone App Prowl (L<http://prowl.weks.net/>).

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * name (required)

This is the name which appears on the iPhone as application name.

=item * apikey (required)

Set this to the API key you can get from the Settings page on L<http://prowl.weks.net/>.

=back

=head1 SEE ALSO

L<WebService::Prowl>

=head1 AUTHOR

Moritz Onken, <onken@netcubed.de>

=cut