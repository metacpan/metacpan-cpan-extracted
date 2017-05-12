package Labyrinth::Writer::Parser::TT;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Writer::Parser::TT - Template Toolkit Renderer for Labyrinth

=head1 SYNOPSIS

  use Labyrinth::Writer::Parser::TT;
  my $tt = Labyrinth::Writer::Parser::TT->new();
  $tt->parser('mytemplate.html');

=head1 DESCRIPTION

This package provides the ability to parse a given template, with a given set
of template variables using Template Toolkit.

=cut

# -------------------------------------
# Library Modules

use Template;

use Labyrinth::Audit;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my %config = (                              # default config info
    RELATIVE        => 1,
    ABSOLUTE        => 1,
    INTERPOLATE     => 0,
    POST_CHOMP      => 1,
    TRIM            => 1,
);

# -------------------------------------
# The Subs

=head1 METHODS

=over 4

=item new

Object constructor.

=item parser( $template, $variables )

Parses a given template, via Template Toolkit. Returns a string of the 
parsed template.

=item parse_to_file( $template, $variables, $file, $binary )

Parses a given template, via Template Toolkit. Writes the result to the named
file, marking as binary if requested.

=back

=cut

sub new {
    my($class) = @_;

    my $self = bless { config => \%config }, $class;
    $self;
}

sub parser {
    my ($self, $layout, $vars) = @_;
    my $path = $settings{'templates'};
    my $output;

#    use Data::Dumper;
#    LogDebug( "layout=[$layout]" );
#    LogDebug( "vars=".Dumper($vars) );

    $self->{config}{INCLUDE_PATH} = $path;
    $self->{config}{EVAL_PERL}    = ($settings{evalperl} || $vars->{evalperl} ? 1 : 0);
    $self->{config}{OUTPUT_PATH}  = $vars->{cache};

    my $parser = Template->new($self->{config});        # initialise parser
    eval { $parser->process($layout,$vars,\$output) };
    die "TT PARSER ERROR: " . $parser->error()    if($@ || !$output);

    return \$output;
}

sub parse_to_file {
    my ($self, $layout, $vars, $file, $binary) = @_;
    my $path = $settings{'templates'};

#    use Data::Dumper;
    LogDebug( "file=[$file], binary=[$binary]" );
#    LogDebug( "layout=[$layout]" );
#    LogDebug( "vars=".Dumper($vars) );

    $self->{config}{INCLUDE_PATH} = $path;
    $self->{config}{EVAL_PERL}    = ($vars->{evalperl} ? 1 : 0);
    $self->{config}{OUTPUT_PATH}  = $vars->{cache};

    my $parser = Template->new($self->{config});        # initialise parser

    eval {
        if($binary) {
            # parse to binary
            $parser->process($layout,$vars,$file, binmode => 1) or die $parser->error();
        } else {
            # parse to text
            $parser->process($layout,$vars,$file) or die $parser->error();
        }
    };

    die "TT PARSER ERROR: eval=$@, error=" . $parser->error  if($@);
}

1;

__END__

=head1 SEE ALSO

  Template (Template Toolkit)
  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
