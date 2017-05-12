package ExtUtils::ModuleMaker::Initializers;
use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.56;
use ExtUtils::ModuleMaker::Licenses::Standard qw(
    Get_Standard_License
    Verify_Standard_License
);
use ExtUtils::ModuleMaker::Licenses::Local qw(
    Get_Local_License
    Verify_Local_License
);

=head1 NAME

ExtUtils::ModuleMaker::Initializers - Methods used within C<ExtUtils::ModuleMaker::new()> and C<ExtUtils::ModuleMaker::Interactive::Main_Menu>

=head1 DESCRIPTION

The methods described below are 'quasi-private' methods which are called by
certain publicly available methods of ExtUtils::ModuleMaker and
ExtUtils::ModuleMaker::Interactive.  They are 'quasi-private' in the sense
that they are not intended to be called by the everyday user of
ExtUtils::ModuleMaker.  Nothing prevents a user from calling these
methods, but they are documented here primarily so that users
writing plug-ins for ExtUtils::ModuleMaker will know what methods
need to be subclassed.  I<Since they are not part of the public interface, their
names and functionality may change in future versions of
ExtUtils::ModuleMaker.>

The methods below are called in C<ExtUtils::ModuleMaker::new()> but not in
that same package's C<complete_build>.  For methods called in
C<complete_build>, please see ExtUtils::ModuleMaker::StandardText.  Some of
the methods below are also called within methods in
ExtUtils::ModuleMaker::Interactive.

Subclassers:  At ExtUtils::ModuleMaker's current state of development, it is 
recommended that you I<not> subclass these methods but instead focus your
efforts on subclassing the methods in ExtUtils::ModuleMaker::StandardText.
The latter package's methods focus more closely on the structure and content
of the files built by ExtUtils::ModuleMaker.

Happy subclassing!

=head1 METHODS

=head2 Methods Called within C<new()>

=head3 C<set_author_composite>

  Usage     : $self->set_author_composite() within new() and
              Interactive::Main_Menu()
  Purpose   : Sets $self key COMPOSITE by composing it from $self keys AUTHOR,
              CPANID, ORGANIZATION, EMAIL and WEBSITE
  Returns   : n/a
  Argument  : n/a
  Comment   : 

=cut

sub set_author_composite {
    my $self = shift;

    my ($cpan_message, $org, $web, $composite);
    $cpan_message = "CPAN ID: $self->{CPANID}" if $self->{CPANID}; 
    $org = $self->{ORGANIZATION} if $self->{ORGANIZATION}; 
    $web = $self->{WEBSITE} if $self->{WEBSITE}; 
    my @data = (
            $self->{AUTHOR},
            $cpan_message,
            $org,
            $self->{EMAIL}, 
            $web,
    );
    $composite = "    $data[0]";
    for my $el (@data[1..$#data]) {
        $composite .= "\n    $el" if defined $el;
    }
    $self->{COMPOSITE} = $composite;
}

=head3 C<set_file_composite>

  Usage     : $self->set_file_composite() within new()
  Purpose   : Sets $self key COMPOSITE by composing it from $self key NAME
  Returns   : n/a
  Argument  : n/a
  Comment   : 

=cut

sub set_file_composite {
    my $self = shift;

    my @layers = split( /::/, $self->{NAME} );
    my $file   = pop(@layers);
    $file .= '.pm';
    my $dir         = join( '/', 'lib', @layers );
    $self->{FILE} = join( '/', $dir, $file );
}

=head3 C<set_dates()>

  Usage     : $self->set_dates() within new()
  Purpose   : Sets 3 keys in $self:  year, timestamp and COPYRIGHT_YEAR
  Returns   : n/a
  Argument  : n/a
  Comment   : 

=cut

sub set_dates {
    my $self = shift;
    $self->{year}      = (localtime)[5] + 1900;
    $self->{timestamp} = scalar localtime;
    $self->{COPYRIGHT_YEAR} ||= $self->{year};
}

=head3 C<validate_values()>

  Usage     : $self->validate_values() within complete_build() and 
              Interactive::Main_Menu()
  Purpose   : Verify module values are valid and complete.
  Returns   : Error message if there is a problem
  Argument  : n/a
  Throws    : Will die with a death_message if errors and not interactive.
  Comment   : References many $self keys

=cut

sub validate_values {
    my $self = shift;

    # Key:    short-hand name for error condition
    # Value:  anonymous array holding:
    #   [0]:  error message
    #   [1]:  condition which will generate error message if evals true
    my %error_msg = (
        NAME_REQ    	=> [
            q{NAME is required},
            eval { ! $self->{NAME}; },
        ],
        NAME_ILLEGAL	=> [
            q{Module NAME contains illegal characters},
            eval { $self->{NAME} and $self->{NAME} !~ m/^[\w:]+$/; },
        ],
        ABSTRACT    	=> [
            q{ABSTRACTs are limited to 44 characters},
            eval { length( $self->{ABSTRACT} ) > 44; },
        ],
        CPANID      	=> [
            q{CPAN IDs are 3-9 characters},
            eval { $self->{CPANID} and $self->{CPANID} !~ m/^\w{3,9}$/; },
        ],
        EMAIL       	=> [
            q{EMAIL addresses need to have an at sign},
            eval { $self->{EMAIL} !~ m/.*\@.*/; },
        ],
        WEBSITE     	=> [
            q{WEBSITEs should start with an "http:" or "https:"},
            eval { $self->{WEBSITE} and $self->{WEBSITE} !~ m{https?://.*}; },
        ],
        LICENSE     	=> [
            q{LICENSE is not recognized},
            eval { ! (
                Verify_Local_License($self->{LICENSE})
                ||
                Verify_Standard_License($self->{LICENSE})
        ); },
        ],
    );

    # Errors should be checked in the following order
    my @msgs_ordered = qw(
        NAME_REQ
        NAME_ILLEGAL
        ABSTRACT
        CPANID
        EMAIL
        WEBSITE
        LICENSE
    );

    my @errors;

    foreach my $attr ( @msgs_ordered ) {
        push @errors, $error_msg{$attr}[0] 
                   if $error_msg{$attr}[1];
    }
        
    return 1 unless @errors;
    $self->death_message(\@errors);
}

=head3 C<initialize_license>

  Usage     : $self->initialize_license() within new() and
              Interactive::License_Menu
  Purpose   : Gets appropriate license and, where necessary, fills in 'blanks'
              with information such as COPYRIGHT_YEAR, AUTHOR and
              ORGANIZATION; sets $self keys LICENSE and LicenseParts
  Returns   : n/a
  Argument  : n/a 
  Comment   :

=cut 

sub initialize_license {
    my $self = shift;

    $self->{LICENSE} = lc( $self->{LICENSE} );

    my $license_function = Get_Local_License( $self->{LICENSE} )
      || Get_Standard_License( $self->{LICENSE} );

    if ( ref($license_function) eq 'CODE' ) {
        $self->{LicenseParts} = $license_function->();

        $self->{LicenseParts}{LICENSETEXT} =~
          s/###year###/$self->{COPYRIGHT_YEAR}/ig;
        $self->{LicenseParts}{LICENSETEXT} =~
          s/###owner###/$self->{AUTHOR}/ig;
        $self->{LicenseParts}{LICENSETEXT} =~
          s/###organization###/$self->{ORGANIZATION}/ig;
    }

}

=head1 SEE ALSO

F<ExtUtils::ModuleMaker>.

=cut

1;


