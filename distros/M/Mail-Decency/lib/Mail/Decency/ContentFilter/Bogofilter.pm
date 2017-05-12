package Mail::Decency::ContentFilter::Bogofilter;

use Moose;
extends qw/
    Mail::Decency::ContentFilter::Core
/;

with qw/
    Mail::Decency::ContentFilter::Core::Spam
    Mail::Decency::ContentFilter::Core::Cmd
    Mail::Decency::ContentFilter::Core::User
    Mail::Decency::ContentFilter::Core::WeightTranslate
/;

use version 0.74; our $VERSION = qv( "v0.1.6" );

use mro 'c3';
use Data::Dumper;
use File::Temp qw/ tempfile /;

=head1 NAME

Mail::Decency::ContentFilter::Bogofilter

=head1 DESCRIPTION

Filter messages through bogofilter and translate results

=head2 CONFIG

    ---
    
    disable: 0
    
    apply_spamicity: 0
    
    cmd_check: '/usr/bin/bogofilter -c %user% -U -I %file% -v'
    cmd_learn_spam: '/usr/bin/bogofilter -c %user% -s -I %file%'
    cmd_unlearn_spam: '/usr/bin/bogofilter -c %user% -N -I %file%'
    cmd_learn_ham: '/usr/bin/bogofilter -c %user% -n -I %file%'
    cmd_unlearn_ham: '/usr/bin/bogofilter -c %user% -S -I %file%'
    
    default_user: '/etc/bogofilter.cf'
    

=cut

has cmd_check => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/bin/bogofilter -c %user% -U -I %file% -v'
);

has cmd_learn_spam => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/bin/bogofilter -c %user% -s -I %file%'
);

has cmd_unlearn_spam => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/bin/bogofilter -c %user% -N -I %file%'
);

has cmd_learn_ham => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/bin/bogofilter -c %user% -n -I %file%'
);

has cmd_unlearn_ham => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/bin/bogofilter -c %user% -S -I %file%'
);

has apply_spamicity => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

has config_params => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [ qw/ apply_spamicity / ] }
);


=head1 METHODS


=head2 handle_filter_result

=cut

sub handle_filter_result {
    my ( $self, $result ) = @_;
    
    # parse result
    my ( $line ) = map {
        my ( $v ) = $_=~ /^X-Bogosity:\s+(.*?)$/;
        $v;
    } grep {
        /^X-Bogosity:/;
    } split( /\n/, $result );
    $self->logger->debug3( "Bogofilter response: '$result' -> LINE '$line'" );
    
    # found status ?
    if ( $line ) {
        
        # parse attributes
        my %parsed = map {
            my ( $n, $v ) = $_=~ /^([^=]+)=(.*$)$/;
            ( $n => $v );
        } grep {
            /=/
        } split( /\s*,\s*/, $line || "" );
        
        # init unsure weight with zero
        my $weight = 0;
        
        # wheter the whole is spam!
        my $status = index( $line, 'Ham' ) == 0
            ? 'ham'
            : ( index( $line, 'Spam' ) == 0
                ? 'spam'
                : 'unsure'
            )
        ;
        
        # init info
        my @info = ( "Bogofilter status: $status" );
        my $spamicity = $parsed{ spamicity } || 'unknown';
        push @info, "Bogofilter spamicity: $parsed{ spamicity }"
            if defined $parsed{ spamicity };
        
        # found spam -> use as spam
        if ( $status eq 'spam' ) {
            $weight = $self->weight_spam;
            $weight *= $parsed{ spamicity }
                if $self->apply_spamicity && defined $parsed{ spamicity };
            $self->logger->debug0( "Use spam status, set score to '$weight' (spamicity: $spamicity)" );
        }
        
        # found ham -> use as ham
        elsif ( $status eq 'ham' ) {
            $weight = $self->weight_innocent;
            $weight = $weight * ( 1 - $parsed{ spamicity } )
                if $self->apply_spamicity && defined $parsed{ spamicity };
            $self->logger->debug0( "Use ham status, set score to '$weight' (spamicity: $spamicity)" );
        }
        
        # add weight to content filte score
        return $self->add_spam_score( $weight, \@info );
    }
    
    else {
        $self->logger->error( "No result from bogofilter: '$result'" );
    }
    
    
    # return ok
    return ;
}


=head1 SEE ALSO

=over

=item * L<Mail::Decency::ContentFilter::Core::Cmd>

=item * L<Mail::Decency::ContentFilter::Core::Spam>

=item * L<Mail::Decency::ContentFilter::Core::WeightTranslate>

=item * L<Mail::Decency::ContentFilter::CRM114>

=item * L<Mail::Decency::ContentFilter::DSPAM>

=back

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
