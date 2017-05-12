package HTTP::RecordedSession;
use strict;
use vars qw( $VERSION );
$VERSION = '0.05';

sub new {
    my ( $proto ) = shift;
    my ( $class ) = ref( $proto ) || $proto;
    my ( $self )  = {};
    bless( $self, $class ); 
    $self->_init( @_ );
    return $self;
}

sub _init {
    my ( $self ) = shift;

    my ( %args ) = (@_);
    $self->{uc($_)} = $args{$_} foreach (keys %args);

    #assign defaults, if necessary
    $self->{ PATH } = "/usr/tmp" unless ( defined $self->{ PATH } );
    $self->{ TEST_MOD } = "Monkeywrench" unless ( defined $self->{ TEST_MOD } );

    $self->{ CLICK_AREF } = $self->_deserialize_clicks; 
}

sub get_id {
    my ( $self ) = shift;
    return $self->{ CONFIG_ID };
}

sub get_clicks {
    my ( $self ) = shift;
    return $self->{ CLICK_AREF };
}

sub _deserialize_clicks {
    my ( $self ) = shift;

    use Storable qw( lock_retrieve );
    my ( $file_path ) = $self->{ PATH } . "recorder_conf_" . $self->{ CONFIG_ID };
    my ( $hashref ) = lock_retrieve( $file_path );

    my ( $session_aref );
    use Data::Dumper;
    if ( $self->{ TEST_MOD } =~ /Monkeywrench/i ) { $session_aref = $self->_format_for_mw( $hashref ) }
    elsif ( $self->{ TEST_MOD } =~ /WebTest/i )   { $session_aref = $self->_format_for_wt( $hashref ) }
    else { die "Please specify either WebTest or Monkeywrench as the value of the test_mod hash element" }
    return $session_aref;
}

sub _format_for_mw {
    my ( $self ) = shift;
    my ( $hashref ) = shift;
    my ( @keys ) = sort keys %$hashref;
    my ( @session );
    foreach my $key ( @keys ) {
	push( @session, $hashref->{ $key } );
    }
    return \@session;
}

sub _format_for_wt {
    my ( $self ) = shift;
    my ( $hashref ) = shift;
    my ( @keys ) = sort keys %$hashref;
    my ( @session );
    foreach my $key ( @keys ) {
	foreach my $element (keys %{ $hashref->{ $key } } ) {
	    if ( $element eq 'acceptcookie' ) { 
		$hashref->{ $key }{ 'accept_cookies' } = $hashref->{ $key }{ $element };
		if ( $hashref->{ $key }{ 'accept_cookies' } == 1 ) {
		    $hashref->{ $key }{ 'accept_cookies' } = 'yes';
		}
		else { 
		    $hashref->{ $key }{ 'accept_cookies' } = 'no';
		}
		delete $hashref->{ $key }{ $element };
	    }
	    if ( $element eq 'sendcookie' ) { 
		$hashref->{ $key }{ 'send_cookies' } = $hashref->{ $key }{ $element };
		if ( $hashref->{ $key }{ 'send_cookies' } == 1 ) {
		    $hashref->{ $key }{ 'send_cookies' } = 'yes';
		}
		else { 
		    $hashref->{ $key }{ 'send_cookies' } = 'no';
		}
		delete $hashref->{ $key }{ $element };
	    }
	    $hashref->{ $key }{ $element } = lc( $hashref->{ $key }{ $element } ) if ( $element eq 'method' );
	    $hashref->{ $key }{ test_name } = "$key";
	}
	push( @session, $hashref->{ $key } );
    }
    return \@session;
}
1;

=head1 NAME

HTTP::RecordedSession - Class to interface with serialized clicks from Apache::Recorder

=head1 SYNOPSIS

Two sample scripts are provided below: one for HTTP::Monkeywrench, and one for 
HTTP::WebTest.

###################### Monkeywrench #####################

use strict;

use HTTP::RecordedSession;

use HTTP::Monkeywrench;

my ( $config_id ) = '1WFmxpCj';  #ID from recorder.pl

my ( $conf ) = new HTTP::RecordedSession( 
    config_id => $config_id, 
    path      => "/usr/tmp/",    # optional
    test_mod  => "Monkeywrench", # optional
);

my ( $clicks ) = $conf->get_clicks;

my ( %settings ) = (       #See Monkeywrench docs
    show_cookies  => '1',
    print_results => '1',
);

my ( $wrench ) = HTTP::Monkeywrench->new( \%settings );

$wrench->test( $clicks );

###################### WebTest #########################

use strict;

use HTTP::RecordedSession;

use HTTP::WebTest qw( run_web_test );

my ( $config_id ) = '1WFmxpCj';  #ID from recorder.pl

my ( $conf ) = new HTTP::RecordedSession( 
    config_id => $config_id,
    path      => "/usr/tmp/",       # optional
    test_mod  => "WebTest",         # optional
);

my ( $clicks ) = $conf->get_clicks;

my ( %options ) = (     #See WebTest docs
    show_cookies => 'yes',
    terse        => 'summary',
);

my ( $num_fail, $num_succeed );

my ( $results ) = run_web_test($clicks, \$num_fail, \$num_succeed, \%options);

#######################

=head1 DESCRIPTION

HTTP::RecordedSession will correctly format the output of Apache::Recorder 
for a script that uses either HTTP::Monkeywrench or HTTP::WebTest.

The HTTP::RecordedSession::new() method accepts a hashref with three 
possible elements:

=over 4

=item * config_id: This is the id provided by recorder.pl when you first 
begin recording an HTTP session.  This element is required.

=item * path: This is intended to provide greater portability -- you do 
not have to use the (Linux-based) default path of "/usr/tmp/", 
although RecordedSession will default to this to ensure backwards 
compatibility if no path is provided.
      

=item * test_mod: This option allows you to choose between HTTP::
Monkeywrench and HTTP::WebTest to actually test your recorded 
session.  HTTP::RecordedSession will default to 'Monkeywrench' 
to ensure backwards compatibility.

=back

There are only three public methods:

=over 4

=item * new()

=item * get_clicks: this method returns the clicks formatted for either HTTP::Monkeywrench
or HTTP::WebTest.

=item * get_id: this method returns the config_id that is passed to the 
HTTP::RecordedSession constructor.

=back

=head2 Notes: 

=over 4

=item * Scripts that were written using HTTP::RecordedSession version 0.03 are not 
compatible out of the box with scripts written using version 0.04.  The $self->get_clicks
method returned an arrayref to an arrayref of hashrefs in version 0.03.  This has been
fixed in version 0.04, so that $self->get_clicks returns a simple arrayref of hashrefs.
In terms of code, you need to change:


my ( $clicks ) = @{ $conf->get_clicks };

to:

my ( $clicks ) = $conf->get_clicks;

Apologies for the inconvenience.

=item * By default HTTP::RecordedSession sets the acceptcookie / sendcookie (Monkeywrench) and 
accept_cookies / send_cookies (WebTest) parameters to 1 and yes respectively.  You can change
this behavior for the entire test in the %options hash.  However, if you only want to change
it for a subset of the clicks in $clicks, you will (at present) need to loop through the 
clicks and set them by hand.

=back

=head1 AUTHOR

Chris Brooks <cbrooks@organiccodefarm.com>

=head1 SEE ALSO

Apache::Recorder

HTTP::Monkeywrench

HTTP::WebTest

=cut
