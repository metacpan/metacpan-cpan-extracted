package Mail::Decency::ContentFilter::CRM114;

use Moose;
extends qw/
    Mail::Decency::ContentFilter::Core
/;
with qw/
    Mail::Decency::ContentFilter::Core::Cmd
    Mail::Decency::ContentFilter::Core::Spam
    Mail::Decency::ContentFilter::Core::User
    Mail::Decency::ContentFilter::Core::WeightTranslate
/;

use version 0.74; our $VERSION = qv( "v0.1.6" );

use mro 'c3';
use Data::Dumper;
use File::Temp qw/ tempfile /;

=head1 NAME

Mail::Decency::ContentFilter::CRM114

=head1 DESCRIPTION

Filters messages trough crm114 discriminator.

=head2 CONFIG

    ---
    
    disable: 0
    
    cmd_train: '/usr/share/crm114/mailreaver.crm --fileprefix=%user% -u %user% --report_only'
    cmd_learn_spam: '/usr/share/crm114/mailfilter.crm --fileprefix=%user% -u %user% --learnspam'
    cmd_unlearn_spam: '/usr/share/crm114/mailfilter.crm --fileprefix=%user% -u %user% --learngood'
    cmd_learn_ham: '/usr/share/crm114/mailfilter.crm --fileprefix=%user% -u %user% --learngood'
    cmd_unlearn_ham: '/usr/share/crm114/mailfilter.crm --fileprefix=%user% -u %user% --learnspam'
    
    
    # set a global crm directory .. for isp like configs, not per user
    #   the "/" at the end is important!!
    default_user: /var/spool/crm114/
    
    # weight for known innocent (good) mails
    #weight_innocent: 20
    
    # weight for known spam (bad) mails
    #weight_spam: -100
    
    # translate crm114 generated weightings into weightings
    #   used in the content filter context (can't use each's
    #   content filter out, cause they use their own scale)
    #   the following translated any crm114 score equal or
    #   bigger then 1 to 100, any score between 1 and -2 to
    #   internal score of 0 and anything below 
    weight_translate:
        1: 100
        -2: 0
        -3: -100
    

=head2 INSTALL CRM114

This is a very simplified installation. For detailed information
and more in-depth information refer to google.

Assuming you don't want an per-user but a global css database...

First of get crm. In a debian system that would be:

    aptitude install crm114

(for source compilation or other distries refer to google)

Then make some crm114 directory. This might get large (depending
on the amount of trained mails)

    mkdir /var/spool/crm114
    cd /var/spool/crm114

Now copy the basic configuration files there

    cp /usr/share/crm114/mailfilter.cf .

Create empty priority and whitelist files

    touch rewrites.mfp priolist.mfp whitelist.mfp blacklist.mfp

Create empty css files for spam and ham

    cssutil -b -r spam.css
    cssutil -b -r nonspam.css

Make some modifications in the config file mailfilter.cf
(again: google for info about that matter)

    :spw: /mypassword/
    :add_verbose_stats: /no/
    :add_extra_stuff: /no/
    :rewrites_enabled: /no/
    :spam_flag_subject_string: //
    :unsure_flag_subject_string: //
    :log_to_allmail.txt: /no/

Mark the following for later tuning:

    :good_threshold: /10.0/
    :spam_threshold: /-5.0/

Now allow your decency filter user write-access to the config dir

    chown -R mailuser:mailgroup /var/spool/crm114

=head2 TRAIN

Train your first mails into crm like this.

    /usr/share/crm114/mailtrainer.crm --spam=/path/to/spamdir --good=/path/to/hamdir \
        --fileprefix=/var/spool/crm114/


=head1 CLASS ATTRIBUTES

=cut

has cmd_check => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/share/crm114/mailreaver.crm --fileprefix=%user% -u %user% --report_only'
);

has cmd_learn_spam => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/share/crm114/mailfilter.crm --fileprefix=%user% -u %user% --learnspam'
);

has cmd_unlearn_spam => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/share/crm114/mailfilter.crm --fileprefix=%user% -u %user% --learngood'
);

has cmd_learn_ham => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/share/crm114/mailfilter.crm --fileprefix=%user% -u %user% --learngood'
);

has cmd_unlearn_ham => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/share/crm114/mailfilter.crm --fileprefix=%user% -u %user% --learnspam'
);

=head1 METHODS


=head2 handle_filter_result

=cut

sub handle_filter_result {
    my ( $self, $result ) = @_;
    
    my %header;
    
    # parse result
    my %parsed = map {
        my ( $n, $v ) = /^X-CRM114-(\S+?):\s+(.*?)$/;
        ( $n => lc( $v ) );
    } grep {
        /^X-CRM114-/;
    } split( /\n/, $result );
    
    # found status ?
    if ( $parsed{ Status } ) {
        my $weight = 0;
        
        my $status = index( $parsed{ Status }, 'spam' ) > -1
            ? 'spam'
            : ( index( $parsed{ Status }, 'good' ) > -1
                ? 'good'
                : 'unsure'
            )
        ;
        my @info = ( "CRM114 status: $status" );
        
        # translate weight from crm114 to our requirements
        if ( $self->has_weight_translate ) {
            
            # extract weight
            ( $weight ) = $parsed{ Status } =~ /^.*?\(\s+(\-?\d+\.\d+)\s+\).*?/;
            my $orig_weight = $weight;
            
            # remember info for headers
            push @info, "CRM114 score: $orig_weight";
            
            # translate weight
            $weight = $self->translate_weight( $orig_weight );
            
            $self->logger->debug0( "Translated score from '$orig_weight' to '$weight'" );
        }
        elsif ( $status eq 'spam' ) {
            $weight = $self->weight_spam;
            $self->logger->debug0( "Use spam status, set score to '$weight'" );
        }
        elsif ( $status eq 'good' ) {
            $weight = $self->weight_innocent;
            $self->logger->debug0( "Use good status, set score to '$weight'" );
        }
        
        # add weight to content filte score
        return $self->add_spam_score( $weight, \@info );
    }
    
    else {
        $self->logger->error( "Could not retreive status from CRM114 result '$result'" );
    }
    
    # return ok
    return ;
}


=head2 get_user_fallback

CRM114 runs normally with $USER_HOME/.crm114 .. this fallback method implements that. As long as no "cmd_user" is set, it will be used.

=cut

sub get_user_fallback {
    my ( $self ) = @_;

    my ( $user, $domain ) = split( /@/, $self->to, 2 );
    return unless $user;
    my $uid = getpwnam( $user );
    return unless $uid;
    $user = ( getpwuid( $uid ) )[-2];
    $user .= "/.crm114";
    
    return $user;
}


=head1 SEE ALSO

=over

=item * L<Mail::Decency::ContentFilter::Core::Cmd>

=item * L<Mail::Decency::ContentFilter::Core::Spam>

=item * L<Mail::Decency::ContentFilter::Core::WeightTranslate>

=item * L<Mail::Decency::ContentFilter::Bogofilter>

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
