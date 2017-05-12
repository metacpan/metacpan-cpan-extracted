package Excel::Template::TT;

use strict;
use warnings;
our $VERSION = '0.0.1';

use File::Temp qw(tempfile);
use Template;

use base qw(Excel::Template);

sub parse_xml {
    my($self, $file) = @_;

    my($fh, $tempfile) = tempfile;

    my $tt = Template->new($self->{CONFIG} || {});
    $tt->process(
        $file,
        $self->{VARS} || {},
        $fh,
    );
    close $fh;

    $self->{tempfile} = $tempfile;

    $self->SUPER::parse_xml($tempfile);
}

sub DESTROY {
    my $self = shift;

    unlink $self->{tempfile};
}

1;
__END__

=head1 NAME

Excel::Template::TT - wrapper class for Excel::Template to using TT

=head1 SYNOPSIS

  use Excel::Template::TT;
  
  # some TT options
  my $config = {
      INTERPOLATE => 1,
      EVAL_PERL   => 1,
  }
  
  # set variables for replacement
  my $vars = {
      worksheet => [
          { name => $value1 },
          { name => $value2 },
          { name => $value3 },
      ],
  };
  
  # create object
  my $template = Excel::Template::TT->new(
      filename => 'sample.xml',
      config   => $config,
      vars     => $vars,
  );
  
  $template->write_file('sample.xls');

=head1 DESCRIPTION

This module is wrapper class for Excel::Template to using Template Toolkit.

=head1 AUTHOR

Taro Funaki E<lt>t@33rpm.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=head1 SEE ALSO

L<Excel::Template::TT>, L<Template>

=cut
