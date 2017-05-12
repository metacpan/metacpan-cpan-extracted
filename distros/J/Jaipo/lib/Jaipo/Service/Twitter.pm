package Jaipo::Service::Twitter;
use warnings;
use strict;
use Net::Twitter;
use base qw/Jaipo::Service Class::Accessor::Fast/;
use Text::Table;
use App::Cache;
use Lingua::ZH::Wrap 'wrap';
use utf8;

=head2 Jaipo::UI::Console

=head3 Twitter Service Command

=item ? 

help message

=item rd 

read direct messages

=item rr

read reply messages

=item rp

read public messages

=item rf

read followed timeline messages

=item sd [ID]  [MESSAGE]

send direct message

=item sr [ID]  [MESSAGE]

send reply message

=item w [ID]

check someone's profile

=item l [LOCATION]

LOCATION is a string, which will be updated to your profile

=item f [ID]

follow someone

=item show friends

show friends

=item show followers

show followers

=cut

sub init {
    my $self   = shift;
    my $caller = shift;
    my $opt = $self->options;

    unless( $opt->{username} and $opt->{access_token} and $opt->{access_token_secret} ) {

        # request to setup parameter
        # XXX TODO: simplify this, let it like jifty dbi schema  or
        # something
        $caller->setup_service ( {
                package_name => __PACKAGE__,
                require_args => [
                	{
                        username => {
                            label       => 'Username',
                            description => '',
                            type        => 'text'
                        }
                    },
                    {   	access_token => {
                            label       => 'OAuth_Token',
                            description => '',
                            type        => 'text'
                        }
                    },
                    {   	access_token_secret => {
                            label       => 'OAuth_Token_Secret',
                            description => '',
                            type        => 'text'
                        }
                    },
                ]
            },
            $opt
        );
    }

    Jaipo->config->set_service_option( 'Twitter' , $opt );
    my %twitter_opt = %{ $opt };

    # default options
    $twitter_opt{useragent} = 'jaipopm';
    $twitter_opt{source}    = 'jaipopm';
    $twitter_opt{clienturl} = 'http://jaipo.org/';
    $twitter_opt{clientver} = '0.001';
    $twitter_opt{clientname} = 'Jaipo.pm';
    $twitter_opt{consumer_key} = 'C5ruz1vl9H5iUYgM9ptbpg';
    $twitter_opt{consumer_secret} = 'qEUKQJWq0OwCcXgEcu6ZC9bCbOAyPeR0pNeUihyc';
    $twitter_opt{traits} = [qw/API::RESTv1_1/];
    
    delete $twitter_opt{username};  # FIXME: with this, Net::Twitter will use Basic Auth

    my $twitter = Net::Twitter->new( %twitter_opt );

    unless( $twitter ) {
        # XXX: need to implement logger:  Jaipo->log->warn( );
        print "twitter init failed\n";
    }

    print "Twitter Service: " . $opt->{username} . ' => ' . $opt->{trigger_name} . "\n";
    $self->core( $twitter );
}


=head2 PRIVATE FUNCTIONS

=cut


sub get_table {
    my $self = shift;
    my @cols = @_;
    my $tb = Text::Table->new( @cols );
    return $tb;
}


sub layout_message {
    my ( $self , $lines ) = @_;
    local $Lingua::ZH::Wrap::columns = 60;
    local $Lingua::ZH::Wrap::overflow = 0;

    # XXX: lingua::zh::wrap url ... orz
    my $out = "";
    for ( @$lines ) {
        my $source = $_->{source};
        # $source =~ s{<a href="(.*?)">(.*?)</a>}{$2 ($1)};
        $source =~ s{<a href="(.*?)">(.*?)</a>}{$2};

        my $text = $_->{text} ;
        $text =~ s|(http://\S*)|\n$1\n|g ;
        my @text_lines = split /\n/,$text;

		my $wrap_text = '';
        for my $l ( @text_lines ) {
            if( $l !~ m{http://} ) {
                $wrap_text .= wrap( ' ' x 4 , ' ' x 4 , $l ) . "\n";
            }
            else {
                $wrap_text .= ' ' x 4 . $l . "\n";
            }
        }

        $out .= qq|
@{[ $_->{user}->{name} ]} said:
$wrap_text
                    -- from $source 
|;
    }
    return $out;

    # XXX: we disable text::table currently
    # force Message column to be 60 chars width or more.
#   my $tb = $self->get_table( qw|User Source Message| );
#    for ( @$lines ) {
#       my $source = $_->{source};
#       # $source =~ s{<a href="(.*?)">(.*?)</a>}{$2 ($1)};
#       $source =~ s{<a href="(.*?)">(.*?)</a>}{$2};
#       $tb->add( $_->{user}->{name} , $source , wrap( $_->{text} )  );
#    }
#   return $tb->table . "";
}

sub get_cache {
    my $cache = App::Cache->new({ ttl => 60*60*3 });
    return $cache;
}

sub filter_read_message {
    my $lines = shift;
    my $cache = get_cache;
    my $new_lines = [];
    for ( @$lines ) {
        my $read = $cache->get('twitter_' . $_->{id} );
        unless( $read ) {
            push @$new_lines , $_;
            $cache->set('twitter_' . $_->{id} , 1 );
        }
    }
    return $new_lines;
}


=head2 SERVICE OVERRIDE FUNCTIONS

=cut

sub send_msg {
    my ( $self , $message ) = @_;
    $message =~ s/^s(end)? //;
    print "Sending to => " if( Jaipo->config->app('Verbose') );
    print $self->options->{trigger_name};
    my $result = $self->core->update({ status => $message });
    print " [Done]\n"    if( Jaipo->config->app('Verbose') );
}

# updates from user himself
sub read_user_timeline {
    my $self = shift;
    my $lines = $self->core->user_timeline;  # XXX: give args to this method
    
    $lines = filter_read_message( $lines );
    Jaipo->logger->info( $self->layout_message( $lines ) );
    return { 
        type => 'notification',
        message => scalar @$lines .  ' Updates',
        updates => scalar @$lines
    };
}

# updates from user's friends or channel
sub read_public_timeline {
    my $self = shift;
    my $lines = $self->core->home_timeline;  # XXX: give args to this method
    $lines = filter_read_message( $lines );
    Jaipo->logger->info( $self->layout_message( $lines ) );
    return { 
        type => 'notification',
        message => scalar @$lines .  ' Updates',
        updates => scalar @$lines
    };
}


sub read_global_timeline {
    my $self = shift;
    
    print "Twitter stopped supporting public_timeline since 2012\n";
    
    #~ my $lines = $self->core->public_timeline;  # XXX: give args to this method
    
    #~ $lines = filter_read_message( $lines );
    #~ Jaipo->logger->info( $self->layout_message( $lines ) );
    #~ return {
        #~ type    => 'notification',
        #~ message => scalar @$lines . ' Updates',
        #~ updates => scalar @$lines
    #~ };
}




1;
