package MYDan::Notify;
use strict;
use warnings;
use Carp;
use YAML::XS;

use File::Basename;
use MYDan::Util::Contact;

my ( %level, %code );
BEGIN{ 
    my $o = MYDan::Util::OptConf->load()->dump( 'notify' ); 
    %level = %{$o->{level}};
    for my $file ( glob "$o->{code}/*" )
    {
        next if $file =~ /\.private$/;
        my $name = basename $file;
        $code{$name} = do( -f "$file.private" ? "$file.private" : $file );
        die "notify load code $name fail"
            unless $code{$name} && ref $code{$name} eq 'CODE';
    }
};

sub new
{
    my ( $class, %this ) = @_;
    bless \%this, ref $class || $class;
}


=head3 notify

user => + { 'user1' => 2, 'user2' => 1 },
mesg = > + { name => 'name1', attr => 'attr1', mesg => 'mesg1', time => 'time'}

=cut

sub notify
{
    my ( $this, %param )= @_;

    my $contact = MYDan::Util::Contact->new();

    my ( $user, $mesg ) = @param{qw( user mesg )};

    my %notify;

    for my $u ( keys %$user )
    {
        my $level = $user->{$u};
        for my $t ( @{$level{$level}} )
        {
            map{ $notify{$t}{$_} = 1 }$contact->contact( $u => $t );
        }
    }

    for my $m ( keys %notify )
    {
        &{$code{$m}}( user => [keys %{$notify{$m}}], mesg => $mesg );
    }
}

1;
