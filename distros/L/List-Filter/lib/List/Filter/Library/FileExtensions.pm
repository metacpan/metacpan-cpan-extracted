package List::Filter::Library::FileExtensions;
use base qw( Class::Base );

=head1 NAME

List::Filter::Library::FileExtensions - filters that select for certain file extensions

=head1 SYNOPSIS

   # This is a plugin, not intended for direct use.
   # See: L<List::Filter::Storage::CODE>

=head1 DESCRIPTION

List::Filter::Library::FileExtensions is a library of L<List::Filter> filters
that select for certain types of files based on standard file extensions.

These definitions are all borrowed from internal definitions in L<App::Ack>.

See L<List::Filter::Library::Documentation> for a information
about the filters defined here.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );

our $VERSION = '0.01';
my $DEBUG = 0;

# needed for accessor generation
our $AUTOLOAD;
my %ATTRIBUTES = ();


=item new

Creates a new List::Filter::Library::FileExtensions object.

With no arguments, the newly created object will have undefined
attributes (which can all be set later using accessors named
according to the "set_*" convention).

Inputs:

An optional hashref, with named fields identical to the names of
the object attributes.  The attributes, in order of likely utility:

=over

=item new

=back

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

=cut

# Note: "new" is inherited from Class::Base and
# calls the following "init" routine automatically.

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  my $lfs = List::Filter::Storage->new( storage =>
                                                    { format => 'MEM', } );

  # define new attributes
  my $attributes = {
           storage_handler            => $args->{ storage_handler } || $lfs,
           };

  # add attributes to object
  my @fields = (keys %{ $attributes });
  @{ $self }{ @fields } = @{ $attributes }{ @fields };    # hash slice

  lock_keys( %{ $self } );
  return $self;
}

=item define_filters_href

Returns a hash reference (keyed by filter name) of filter hash references.

=cut

sub define_filters_href {
  my $self = shift;

  my $filters =
    {
          ':tcl' => {
                      'terms' => [
                                   '\\.tcl$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for tcl files (borrowed from ack)'
                    },
          ':vim' => {
                      'terms' => [
                                   '\\.vim$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for vim files (borrowed from ack)'
                    },
          ':js' => {
                     'terms' => [
                                  '\\.js$'
                                ],
                     'modifiers' => '',
                     'method' => 'find_any',
                     'description' => 'Select for js files (borrowed from ack)'
                   },
          ':html' => {
                       'terms' => [
                                    '\\.htm$',
                                    '\\.html$',
                                    '\\.shtml$'
                                  ],
                       'modifiers' => '',
                       'method' => 'find_any',
                       'description' => 'Select for html files (borrowed from ack)'
                     },
          ':shell' => {
                        'terms' => [
                                     '\\.sh$',
                                     '\\.bash$',
                                     '\\.csh$',
                                     '\\.ksh$',
                                     '\\.zsh$'
                                   ],
                        'modifiers' => '',
                        'method' => 'find_any',
                        'description' => 'Select for shell files (borrowed from ack)'
                      },
          ':tex' => {
                      'terms' => [
                                   '\\.tex$',
                                   '\\.cls$',
                                   '\\.sty$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for tex files (borrowed from ack)'
                    },
          ':lisp' => {
                       'terms' => [
                                    '\\.lisp$'
                                  ],
                       'modifiers' => '',
                       'method' => 'find_any',
                       'description' => 'Select for lisp files (borrowed from ack)'
                     },
          ':python' => {
                         'terms' => [
                                      '\\.py$'
                                    ],
                         'modifiers' => '',
                         'method' => 'find_any',
                         'description' => 'Select for python files (borrowed from ack)'
                       },
          ':java' => {
                       'terms' => [
                                    '\\.java$'
                                  ],
                       'modifiers' => '',
                       'method' => 'find_any',
                       'description' => 'Select for java files (borrowed from ack)'
                     },
          ':tt' => {
                     'terms' => [
                                  '\\.tt$',
                                  '\\.tt2$'
                                ],
                     'modifiers' => '',
                     'method' => 'find_any',
                     'description' => 'Select for tt files (borrowed from ack)'
                   },
          ':perl' => {
                       'terms' => [
                                    '\\.pl$',
                                    '\\.pm$',
                                    '\\.pod$',
                                    '\\.tt$',
                                    '\\.ttml$',
                                    '\\.t$'
                                  ],
                       'modifiers' => '',
                       'method' => 'find_any',
                       'description' => 'Select for perl files (borrowed from ack)'
                     },
          ':mason' => {
                        'terms' => [
                                     '\\.mas$'
                                   ],
                        'modifiers' => '',
                        'method' => 'find_any',
                        'description' => 'Select for mason files (borrowed from ack)'
                      },
          ':css' => {
                      'terms' => [
                                   '\\.css$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for css files (borrowed from ack)'
                    },
          ':elisp' => {
                        'terms' => [
                                     '\\.el$'
                                   ],
                        'modifiers' => '',
                        'method' => 'find_any',
                        'description' => 'Select for elisp files (borrowed from ack)'
                      },
          ':csharp' => {
                         'terms' => [
                                      '\\.cs$'
                                    ],
                         'modifiers' => '',
                         'method' => 'find_any',
                         'description' => 'Select for csharp files (borrowed from ack)'
                       },
          ':asm' => {
                      'terms' => [
                                   '\\.s$',
                                   '\\.S$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for asm files (borrowed from ack)'
                    },
          ':ruby' => {
                       'terms' => [
                                    '\\.rb$',
                                    '\\.rhtml$',
                                    '\\.rjs$'
                                  ],
                       'modifiers' => '',
                       'method' => 'find_any',
                       'description' => 'Select for ruby files (borrowed from ack)'
                     },
          ':php' => {
                      'terms' => [
                                   '\\.php$',
                                   '\\.phpt$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for php files (borrowed from ack)'
                    },
          ':sql' => {
                      'terms' => [
                                   '\\.sql$',
                                   '\\.ctl$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for sql files (borrowed from ack)'
                    },
          ':parrot' => {
                         'terms' => [
                                      '\\.pir$',
                                      '\\.pasm$',
                                      '\\.pmc$',
                                      '\\.ops$',
                                      '\\.pod$',
                                      '\\.pg$',
                                      '\\.tg$'
                                    ],
                         'modifiers' => '',
                         'method' => 'find_any',
                         'description' => 'Select for parrot files (borrowed from ack)'
                       },
          ':cc' => {
                     'terms' => [
                                  '\\.c$',
                                  '\\.h$',
                                  '\\.xs$'
                                ],
                     'modifiers' => '',
                     'method' => 'find_any',
                     'description' => 'Select for cc files (borrowed from ack)'
                   },
          ':cpp' => {
                      'terms' => [
                                   '\\.cpp$',
                                   '\\.m$',
                                   '\\.h$',
                                   '\\.C$',
                                   '\\.H$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for cpp files (borrowed from ack)'
                    },
          ':ocaml' => {
                        'terms' => [
                                     '\\.ml$',
                                     '\\.mli$'
                                   ],
                        'modifiers' => '',
                        'method' => 'find_any',
                        'description' => 'Select for ocaml files (borrowed from ack)'
                      },
          ':xml' => {
                      'terms' => [
                                   '\\.xml$',
                                   '\\.dtd$',
                                   '\\.xslt$'
                                 ],
                      'modifiers' => '',
                      'method' => 'find_any',
                      'description' => 'Select for xml files (borrowed from ack)'
                    },
          ':scheme' => {
                         'terms' => [
                                      '\\.scm$'
                                    ],
                         'modifiers' => '',
                         'method' => 'find_any',
                         'description' => 'Select for scheme files (borrowed from ack)'
                       },
          ':haskell' => {
                          'terms' => [
                                       '\\.hs$',
                                       '\\.lhs$'
                                     ],
                          'modifiers' => '',
                          'method' => 'find_any',
                          'description' => 'Select for haskell files (borrowed from ack)'
                        },
          ':yaml' => {
                       'terms' => [
                                    '\\.yaml$',
                                    '\\.yml$'
                                  ],
                       'modifiers' => '',
                       'method' => 'find_any',
                       'description' => 'Select for yaml files (borrowed from ack)'
                     }
        };
}


=back

=head2 basic setters and getters

=over

=item storage_handler

Getter for object attribute storage_handler

=cut

sub storage_handler {
  my $self = shift;
  my $lfs = $self->{ storage_handler };
  return $lfs;
}

=item set_storage_handler

Setter for object attribute set_storage_handler

=cut

sub set_storage_handler {
  my $self = shift;
  my $lfs = shift;
  $self->{ storage_handler } = $lfs;
  return $lfs;
}


# =back

# =head2  automatic generation of accessors

# =over

# =item AUTOLOAD

# =back

# =cut

# sub AUTOLOAD {
#   return if $AUTOLOAD =~ /DESTROY$/;  # skip calls to DESTROY ()

#   my ($name) = $AUTOLOAD =~ /([^:]+)$/; # extract method name
#   (my $field = $name) =~ s/^set_//;

#   # check that this is a valid accessor call
#   croak("Unknown method '$AUTOLOAD' called")
#     unless defined( $ATTRIBUTES{ $field } );

#   { no strict 'refs';

#     # create the setter and getter and install them in the symbol table

#     if ( $name =~ /^set_/ ) {

#       *$name = sub {
#         my $self = shift;
#         $self->{ $field } = shift;
#         return $self->{ $field };
#       };

#       goto &$name;              # jump to the new method.
#     } elsif ( $name =~ /^get_/ ) {
#       carp("Apparent attempt at using a getter with unneeded 'get_' prefix.");
#     }

#     *$name = sub {
#       my $self = shift;
#       return $self->{ $field };
#     };

#     goto &$name;                # jump to the new method.
#   }
# }


1;

=back

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
18 Jun 2007

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
