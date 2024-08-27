package Pod::Simple::Role::XHTML::WithPostProcess;
use Moo::Role;

our $VERSION = '0.004000';
$VERSION =~ tr/_//d;

use namespace::clean;

around new => sub {
  my $orig = shift;
  my $class = shift;
  my $self = $class->$orig(@_);
  open my $fh, '>', \($self->{__buffer} = '') or die;
  $self->{__real_output_fh} = $self->{output_fh};
  $self->{output_fh} = $fh;
  return $self;
};

around output_fh => sub {
  my $orig = shift;
  my $self = shift;
  if (@_) {
    $self->{__real_output_fh} = $_[0];
  }
  else {
    return $self->{__real_output_fh};
  }
};

around output_string => sub {
  my $orig = shift;
  my $self = shift;
  return $self->$orig(@_)
    if !@_;

  local $self->{output_fh} = $self->{__real_output_fh};
  my $output = $self->$orig(@_);
  $self->{__real_output_fh} = $self->{output_fh};
  return $output;
};

sub pre_process {
  my ($self, $content) = @_;
  return $content;
}

sub post_process {
  my ($self, $output) = @_;
  return $output;
}

after end_Document => sub {
  my ($self) = @_;
  my $full_content = $self->{__buffer};
  $self->{__buffer} = '';
  print { $self->{__real_output_fh} } $self->post_process($full_content);
};

before emit => sub {
  my $self = shift;
  $self->{scratch} = $self->pre_process($self->{scratch});
};

after reinit => sub {
  my $self = shift;
  $self->{__buffer} = '';
};

1;
__END__

=head1 NAME

Pod::Simple::Role::XHTML::WithPostProcess - Post process entire output from XHTML conversion

=head1 SYNOPSIS

  package MyPodParser;
  with 'Pod::Simple::Role::XHTML::WithPostProcess';

  around post_process => sub {
    my ($self, $content) = @_;
    $content =~ s/Foo/Bar/g;
    return $content;
  };

  my $parser = MyPodParser->new;
  $parser->output_string(\my $html);
  $parser->parse_string_document($pod);

=head1 DESCRIPTION

Allows post-processing of entire converted Pod document before outputting. This
role is meant to be used by other roles that need to do post processing on the
full document that is output, rather than as the content is generated. On its
own, this role will not have any impact on the content of the output.

=head1 METHODS

Two methods are provided which should be modified to make use of this role.

=head2 pre_process ( $new_content )

Called when initially adding content to the document. C<$new_content> is the
content being added to the output document. Expected to return the content to
be added to the output.

=head2 post_process ( $full_content )

Called just before outputting the final document. C<$full_content> is the full
output. Expected to return the content to be output.

=head1 SUPPORT

See L<MetaCPAN::Pod::HTML> for support and contact information.

=head1 AUTHORS

See L<MetaCPAN::Pod::HTML> for authors.

=head1 COPYRIGHT AND LICENSE

See L<MetaCPAN::Pod::HTML> for the copyright and license.

=cut
