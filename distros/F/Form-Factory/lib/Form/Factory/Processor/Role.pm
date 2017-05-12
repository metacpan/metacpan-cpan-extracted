package Form::Factory::Processor::Role;
$Form::Factory::Processor::Role::VERSION = '0.022';
use Moose;
use Moose::Exporter;

use Carp ();
use Form::Factory::Action::Role;

Moose::Exporter->setup_import_methods(
    as_is     => [ qw( deferred_value ) ],
    with_meta => [ qw(
        has_control use_feature
        has_cleaner has_checker has_pre_processor has_post_processor
    ) ],
    also      => 'Moose::Role',
);

# ABSTRACT: Moos-ish helper for action roles


sub init_meta {
    my $package = shift;
    my %options = @_;

    Moose::Role->init_meta(%options);

    my $meta = Moose::Util::MetaRole::apply_metaroles(
        for            => $options{for_class},
        role_metaroles => {
            role => [ 'Form::Factory::Action::Meta::Role' ],
        },
    );

    Moose::Util::apply_all_roles(
        $options{for_class}, 'Form::Factory::Action::Role',
    );

    return $meta;
}


sub has_control {
    my ($meta, $name, $args) = Form::Factory::Processor::_setup_control_defaults(@_);
    $meta->add_attribute( $name => %$args );
}


sub use_feature {
    my $meta = shift;
    my $name = shift;
    my $args = @_ == 1 ? shift : { @_ };

    $meta->features->{$name} = $args;
}


sub deferred_value(&) {
    my $code = shift;

    return Form::Factory::Processor::DeferredValue->new(
        code => $code,
    );
}


sub _add_function {
    my ($type, $meta, $name, $code) = @_;
    Carp::croak("bad code given for $type $name") unless defined $code;
    $meta->features->{functional}{$type . '_code'}{$name} = $code;
}

sub has_cleaner        { _add_function('cleaner', @_) }
sub has_checker        { _add_function('checker', @_) }
sub has_pre_processor  { _add_function('pre_processor', @_) }
sub has_post_processor { _add_function('post_processor', @_) }


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Processor::Role - Moos-ish helper for action roles

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Action::Role::HasAuthor;
  use Form::Factory::Processor::Role;

  has_control author => (
      control => 'text',
      features => {
          trim => 1,
          required => 1,
      },
  );

  has_checker authors_should_be_proper_names => (
      my $self = shift;
      my $value = $self->controls->{author}->current_value;

      # We want two words, but only a warning since I have a friend with only
      # one name... we wouldn't want to discriminate.
      $self->warning('you really should use a full name')
          if $value !~ /\w\s+\w/;
      $self->result->is_valid(1);
  );

  package MyApp::Action::Post;
  use Form::Factory::Processor;

  with qw( MyApp::Action::Role::HasAuthor );

  has_control title => (
      control => 'text',
      features => {
          trim => 1,
          required => 1,
      },
  );

  has_control body => (
      control => 'full_text',
      features => {
          trim => 1,
          required => 1,
      },
  );

  sub run {
      my $self = shift;

      my $filename = $self->title . '.txt';
      $filename =~ s/\W+/-/g;

      open my $fh, '>', $filename or die "cannot open $filename: $!";
      print $fh "Title: ", $self->title, "\n";
      print $fh "Author: ", $self->author, "\n";
      print $fh "Body: ", $self->body, "\n";
      close $fh;
  }

=head1 DESCRIPTION

This is a helper class used to define action roles. This class automatically imports the subroutiens described in this documentation as well as any defined in L<Moose::Role>.

You may compose roles defined this way to build a complete action.

=head1 METHODS

=head2 init_meta

Sets up the roles and meta-class information for your action role.

=head2 has_control

  has_control $name => (
      %usual_has_options,

      control  => $control_short_name,
      options  => \%control_options,
      features => \%control_features,
  );

This works very similar to L<Moose::Role/has>. This applies the L<Form::Factory::Action::Meta::Attribute::Control> trait to the attribute and sets up other defaults. These defaults match those shown in L<Form::Factory::Processor/has_control>.

=head2 use_feature

This function is used to make an action role use a particular form feature. You use it like this:

  use_feature $name => \%options;

The C<%options> are optional. So, this is also acceptable:

  use_feature $name;

The C<$name> is a short name for the feature class. For example, the name "require_none_or_all" will load teh feature defined in L<Form::Factory::Features::RequireNoneOrAll>.

=head2 deferred_value

  has_control publish_on => (
      control => 'text',
      options => {
          default_value => deferred_value {
              my ($action, $control_name) = @_;
              DateTime->now->iso8601,
          },
      },
  );

This is a helper for deferring the calculation of a value. This works similar to L<Scalar::Defer> to defer the calculation, but with an important difference. The subroutine is passed the action object (such as it exists while the controls are being constructed) and the control's name. The control itself doesn't exist yet when the subroutine is called.

=head2 has_cleaner

  has_cleaner $name => sub { ... }

Adds some code called during the clean phase.

=head2 has_checker

  has_checker $name => sub { ... }

Adds some code called during the check phase.

=head2 has_pre_processor

  has_pre_processor $name => sub { ... }

Adds some code called during the pre-process phase.

=head2 has_post_processor

  has_post_processor $name => sub { ... }

Adds some code called during the post-process phase.

=head1 SEE ALSO

L<Form::Factory::Action::Role>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
