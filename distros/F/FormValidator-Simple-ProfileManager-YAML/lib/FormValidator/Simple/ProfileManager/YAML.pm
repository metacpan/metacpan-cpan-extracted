package FormValidator::Simple::ProfileManager::YAML;
use strict;

use vars qw($VERSION);
$VERSION = '0.06';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init(@_);
    $self;
}

sub init {
    my ($self, $yaml, $options) = @_;
    $options ||= {};
    my $loader = $options->{loader} || 'YAML';
    if ( $loader eq 'YAML::Syck') {
        require YAML::Syck;
        $self->{_profile} = YAML::Syck::LoadFile($yaml);
    } elsif ( $loader eq 'YAML' ) {
        require YAML;
        $self->{_profile} = YAML::LoadFile($yaml);
    } else {
        die "Don't know loader $loader.";
    }
}

sub extract {
    my $self = shift;
    my $self_new = bless { %$self }, ref $self;
    $self_new->{_profile} = $self_new->get_profile(@_);
    return unless $self_new->{_profile};
    return $self_new;
}

sub get_profile {
    my ($self, @paths) = @_;
    @paths = map { split /\./ } @paths;
    return $self->_get_profile_recursive($self->{_profile}, @paths);
}

sub _get_profile_recursive {
    my ($self, $profile, @paths) = @_;
    if ( @paths ) {
        $profile = $profile->{shift @paths};
        return $profile ? $self->_get_profile_recursive($profile, @paths) : undef;
    } else {
        return $profile;
    }
}

sub add_profile {
    my $self = shift;
    my ($keys, $constraint, @paths) = @_;
    my $prof = $self->get_profile(@paths);

    my $key = $self->_get_key($keys);

    # check key duplication. replace constraint if key already exists.
    my $key_exists;
    for (my $i=0; $i< @$prof; $i+=2) {
        my $cur_key = $self->_get_key($prof->[$i]);
        if ( $key eq $cur_key ) {
            $prof->[$i+1] = $constraint;
            $key_exists++;
            last;
        }
    }
    # push profile unless keys eixsts
    unless ( $key_exists ) {
        push @$prof, $keys, $constraint;
    }

}

sub remove_profile {
    my $self = shift;
    my ($keys, @paths) = @_;
    my $prof = $self->get_profile(@paths);

    my $key = $self->_get_key($keys);

    for (my $i=0; $i< @$prof; $i+=2) {
        my $cur_key = $self->_get_key($prof->[$i]);
        if ( $key eq $cur_key ) {
            splice (@$prof, $i, 2);
            last;
        }
    }

}

sub _get_key {
    my ($self,$keys) = @_;
    if ( my $ref = ref $keys ) {
        if ( $ref eq 'HASH') {
            return (keys %$keys)[0];
        } else {
            die "keys must be a hashref or single scalar.";
        }
    } else {
        return $keys;
    }
}


1;
__END__

=head1 NAME

FormValidator::Simple::ProfileManager::YAML - YAML profile manager for FormValidator::Simple

=head1 SYNOPSIS

  use FormValidator::Simple;
  use FormValidator::Simple::ProfileManager::YAML;

  my $manager = FormValidator::Simple::ProfileManager::YAML->new('/path/to/profile.yml');

  # get profile assosiated with @groups
  my $profile = $manager->get_profile(@groups);

  # pass obtained profile to FormValidator::Simple
  my $result = FormValidator::Simple->check($q, $profile);


  # create new manager associated with group
  my $manager2 = $manager->extract(@groups);


  # you can add profile to @groups
  $manager->add_profile(
      email => [EMAIL],[NOT_BLANK],
      @groups,
  );

  # and also you can remove profile from @groups
  $manager->remove_profile(email, @groups);


  # sample yaml profile

  group1 :
      - name
      - [ [NOT_BLANK] ]
      - email
      - [ [NOT_BLANK], [EMAIL_LOOSE] ]
      - tel
      - [ [NOT_BLANK], [NUMBER_PHONE_JP] ]
      - content
      - [ [NOT_BLANK] ]

  group2 :
     subgroup1 :
         - userid
         - [ [NOT_BLANK]]
         - password
         - [ [NOT_BLANK]]
         - name
         - [ [NOT_BLANK] ]
         - email
         - [ [NOT_BLANK], [EMAIL_LOOSE] ]

     subgroup2 :
         - tel
         - [ [NOT_BLANK], [NUMBER_PHONE_JP] ]
         - { zip : [zip1, zip2] }
         - [ [ZIP_JP] ]
         - address
         - [ [NOT_BLANK] ]


  # get profile 'group1'
  $profile = $manager->get_profile('group1');

  # get profile 'subgroup2'
  $profile = $manager->get_profile( 'group2', 'subgroup2' );
  # or you can use dot syntax.
  $profile = $manager->get_profile( 'group2.subgroup2' );


  # Default YAML loader is 'YAML'.
  # If you want to use 'YAML::Syck' as loader, pass 'loader' to constructor as below.
  my $manager = FormValidator::Simple::ProfileManager::YAML->new(
      '/path/to/profile.yml',
      {
          loader => 'YAML::Syck',
      }
  );



=head1 DESCRIPTION

FormValidator::Simple::ProfileManager::YAML is YAML profile manager for FormValidator::Simple.

=head1 METHODS

=over 4

=item new

  $manager = FormValidator::Simple::ProfileManager::YAML->new('/path/to/profile.yml');
  $manager = FormValidator::Simple::ProfileManager::YAML->new('/path/to/profile.yml', {loader=>'YAML::Syck'});

=item get_profile

  $profile = $manager->get_profile();
  $profile = $manager->get_profile('group1');
  $profile = $manager->get_profile('group1', 'subgroup2');
  $profile = $manager->get_profile('group1.subgroup2');

=item extract

  my $manager2 = $manager->extract(@group);

=item add_profile

  $manager->add_profile(
      email => [EMAIL],[NOT_BLANK],
      @groups,
  );

=item remove_profile

  $manager->remove_profile(email, @groups);

=back

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>yasuhiro@hori-uchi.comE<gt>

=cut
