package Mac::CocoaDialog;

use version; our $VERSION = qv('0.0.3');

use warnings;
use strict;
use Carp;
use English qw( -no_match_vars );
use IO::Handle;

# Module implementation here
sub AUTOLOAD {
   my $self = shift;

   (my $name = our $AUTOLOAD) =~ s{.*::}{}mxs;
   $name =~ tr/_/-/;

   return (ref($self) . '::Runner')->new(%$self, runmode => $name);
} ## end sub AUTOLOAD

sub new {
   my $package = shift;
   my %opts = (@_ == 1) ? %$_ : @_;

   if (exists $opts{path}) {
      croak "cannot find CocoaDialog in provided path"
        unless -x $opts{path};
   }
   else {
      my $canonic =
        '/Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog';
      for my $candidate ($canonic, "$ENV{HOME}/$canonic") {
         next unless -x $candidate;
         $opts{path} = $candidate;
         last;
      }
      croak "cannot find CocoaDialog, please provide full path to it"
        unless -x $opts{path};
   } ## end else [ if (exists $opts{path})

   return bless {path => $opts{path}, cmdline => []}, $package;
} ## end sub new

sub push_params {
   my $self = shift;
   push @{$self->{cmdline}}, @_;
}

sub command_line {
   my $self = shift;
   return @{$self->{cmdline}} unless @_;

   return @_ unless @_ == 2 && ref($_[1]) eq 'HASH';

   my ($cmd, $h) = @_;
   return $cmd, map {
      (my $k = $_) =~ tr/_/-/;
      ('--' . $k) => (ref($h->{$_}) ? @{$h->{$_}} : $h->{$_})
   } keys %$h;
} ## end sub command_line

sub path { return $_[0]->{path} }

sub pipe_from {
   my $self = shift;
   open my $fh, '-|', $self->path(), $self->command_line(@_)
     or croak "open() for output pipe: $OS_ERROR";
   return $fh;
} ## end sub pipe_from

sub qx {
   my $self = shift;
   my $fh   = $self->pipe_from(@_);
   return <$fh> if wantarray;
   return join '', <$fh>;
} ## end sub qx

sub pipe_to {
   my $self = shift;
   open my $fh, '|-', $self->path(), $self->command_line(@_)
     or croak "open() for input pipe: $OS_ERROR";
   $fh->autoflush(1);  # autoflush by default, it's what you want
   return $fh;
} ## end sub pipe_to

sub background_system {
   my $self = shift;

   my $pid = fork();
   die "fork(): $OS_ERROR" unless defined $pid;
   return if $pid;    # father returns immediately

   exec {$self->path()} $self->path(), $self->command_line(@_)
     or die "exec(): $OS_ERROR";
   exit 1;
} ## end sub background_system

sub foreground_system {
   my $self = shift;
   system {$self->path()} $self->path(), $self->command_line(@_);
}

{
   no warnings;
   *grab       = \&qx;
   *foreground = \&foreground_system;
   *background = \&background_system;
}

package Mac::CocoaDialog::Runner;
use strict;
use warnings;
use English qw( -no_match_vars );
use base qw( Mac::CocoaDialog );

sub AUTOLOAD {
   my $self = shift;

   (my $name = our $AUTOLOAD) =~ s{.*::}{}mxs;
   $name =~ tr/_/-/;
   $self->push_params('--' . $name, @_);

   return $self;
} ## end sub AUTOLOAD

sub new {
   my $package = shift;
   my %opts = (@_ == 1) ? %$_ : @_;

   my $self = $package->SUPER::new(%opts);
   $self->push_params($opts{runmode});

   return $self;
} ## end sub new

1;    # Magic true value required at end of module
__END__

=encoding iso-8859-1

=head1 NAME

Mac::CocoaDialog - script with CocoaDialog

=head1 VERSION

This document describes Mac::CocoaDialog version 0.0.1. Most likely, this
version number here is outdate, and you should peek the source.


=head1 SYNOPSIS

   use Mac::CocoaDialog;

   my $cocoa = Mac::CocoaDialog->new('/path/to/CocoaDialog');

   # As factory
   my $bubble = $cocoa->bubble();
   $bubble->text('whatever')->title('Hello!');  # cascaded
   $bubble->no_timeout();  # underscores become dashes
   $bubble->background();  # actual call to CocoaDialog

   # Another one, as factory
   my $multi = $cocoa->bubble();
   $multi->titles(qw( first second third ));
   $multi->texts(qw(   #1     #2    #3 ));
   $multi->no_timeout()->independent()->foreground();

   # Directly from $cocoa object
   $cocoa->foreground(
      'bubble',
      text => 'whatever',
      title => 'Hello!',
      icon => 'heart',
   );


=head1 DESCRIPTION

This module eases calls to the CocoaDialog program in Mac. Be sure to
look at CocoaDialog's documentation at
L<http://cocoadialog.sourceforge.net/> to see what's this all
about. Briefly speaking, CocoaDialog gives you the possibility to
let the user interact with a very basic GUI, providing basic
input boxes, progress bars, etc.

This module is object oriented, and can be used in two different
manners. Either way, first of all you need an object, and to have it
you need to ensure that it's able to find CocoaDialog in some way:

   my $cocoa  = Mac::CocoaDialog->new();  # uses default
   my $cocoa2 = Mac::CocoaDialog->new(path => '/path/to/CocoaDialog');

In the first example, no explicit path is passed, so the module will
try to find it in the following paths (in order):

=over

=item B</Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog>

=item B<~/Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog>

=back

In the second case, the path is explicitly passed and no default is
looked for.

The most direct mode in which you can use this object is by calling
a method that suits to the way you want to interact with the CocoaDialog.
Depending on your needs and on the type of CocoaDialog runmode you
want to use, you can invoke it in different manners:

=over

=item *

piping data to the CocoaDialog. In this case, you'll want a filehandle
where you can send data, and you can get it using the L</pipe_to>
method;

=item *

getting data from the CocoaDialog, either with a filehandle (that 
you can get with L</pipe_from>) or all at once (using method L</qx>
or its alias L</grab>);

=item *

simply calling the CocoaDialog, either in foreground (blocking mode,
using methods L</foreground> or its alias L</foreground_system>)
or in background (using either L</background> or L</background_system>);

=back

Once you have chosen the method that better suits you needs, you simply
have to call it like you were calling the CocoaDialog program, i.e.
passing the runmode and the list of options (where each option's name
starts with C<-->), like this:

   $cocoa->foreground(qw( bubble --title Hello --text World! ));
   my $rv = $cocoa->grab( qw( yesno-msgbox --title Hi --text there ));

If you have your parameters in a hash, you can pass that as well:

   $cocoa->background(bubble => { 
      title => 'Hello',
      text  => 'World!',
   });

In this case, you have to provide the runmode and the hash, in which:

=over

=item B<keys>

will be used as parameter names, with a C<--> prepended and underscores
transformed into dashes;

=item B<values>

will be ignored if C<undef>, expanded if they're a reference to an
array, and used as they are otherwise.

=back

The other way you can use your C<$cocoa> object is like a factory to
get objects for individual runmode calls, in order to "build" your
command line using methods:

   my $bubble = $cocoa->bubble();
   $bubble->text('whatever')->title('Hello!');  # cascaded
   $bubble->no_timeout();  # underscores become dashes
   $bubble->background();  # actual call to CocoaDialog

Each time you call a method for a new parameter on the C<$bubble> 
object, the object itself is given back so that you can cascade
calls. When you're happy with the parameters, you can call one of
the activation methods seen before, without passing any parameter.


=head1 INTERFACE 

=over

=item B<< new >>

create a new instance for interacting with CocoaDialog.

Passing a C<$path> is optional. If C<$path> cannot be found, the module
will try to see if either 
B</Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog>
or 
B<~/Applications/CocoaDialog.app/Contents/MacOS/CocoaDialog>
can be used instead.

=item B<< path >>

get the path to the CocoaDialog program.

=item B<< command_line >>

get the current command line (this is likely to work only when you
use your object as a factory, but give an eye to L</push_params>).


=item B<< push_params >>

register parameters as command line to use by default by the different
invocation methods, when the parameters aren't explicitly passed.

=back

=head2 Invocation Methods

=over

=item B<< foreground >>

=item B<< foreground_system >>

=item B<< background >>

=item B<< background_system >>

call CocoaDialog either in foreground or in background, without
any input/output interaction.

If you don't pass C<@params>, then the output of L</command_line>
will be used. Otherwise, the parameters will be expanded as described
in L</command_line>.

=item B<< qx >>

=item B<< grab >>

grab some stuff from the output of the CocoaDialog invocation.

If you don't pass C<@params>, then the output of L</command_line>
will be used. Otherwise, the parameters will be expanded as described
in L</command_line>.

=item B<< pipe_from >>

get a filehandle to get data from.

If you don't pass C<@params>, then the output of L</command_line>
will be used. Otherwise, the parameters will be expanded as described
in L</command_line>.

=item B<< pipe_to >>

get a filehandle to pass data to (currently this will work only for
a I<progressbar>).

If you don't pass C<@params>, then the output of L</command_line>
will be used. Otherwise, the parameters will be expanded as described
in L</command_line>.

=back

=head1 DIAGNOSTICS

=over

=item C<< cannot find CocoaDialog in provided path >>

you passed a path to CocoaDialog that cannot be executed.

=item C<< cannot find CocoaDialog, please provide full path to it >>

you didn't pass any path to CocoaDialog, and the default positions
didn't work.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Mac::CocoaDialog requires no configuration files or environment variables.


=head1 DEPENDENCIES

None. Apart the fact that it's pretty unuseful without CocoaDialog.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through http://rt.cpan.org/

Note that there are limitation in the allowed values for CocoaDialog
parameters, but this is not a limitation of Mac::CocoaDialog.

=head1 AUTHOR

Flavio Poletti  C<< <flavio [at] polettix [dot] it> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Flavio Poletti C<< <flavio [at] polettix [dot] it> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.x itself. See L<perlartistic>
and L<perlgpl>.

Questo modulo è software libero: potete ridistribuirlo e/o
modificarlo negli stessi termini di Perl 5.8.x stesso. Vedete anche
L<perlartistic> e L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NEGAZIONE DELLA GARANZIA

Poiché questo software viene dato con una licenza gratuita, non
c'è alcuna garanzia associata ad esso, ai fini e per quanto permesso
dalle leggi applicabili. A meno di quanto possa essere specificato
altrove, il proprietario e detentore del copyright fornisce questo
software "così com'è" senza garanzia di alcun tipo, sia essa espressa
o implicita, includendo fra l'altro (senza però limitarsi a questo)
eventuali garanzie implicite di commerciabilità e adeguatezza per
uno scopo particolare. L'intero rischio riguardo alla qualità ed
alle prestazioni di questo software rimane a voi. Se il software
dovesse dimostrarsi difettoso, vi assumete tutte le responsabilità
ed i costi per tutti i necessari servizi, riparazioni o correzioni.

In nessun caso, a meno che ciò non sia richiesto dalle leggi vigenti
o sia regolato da un accordo scritto, alcuno dei detentori del diritto
di copyright, o qualunque altra parte che possa modificare, o redistribuire
questo software così come consentito dalla licenza di cui sopra, potrà
essere considerato responsabile nei vostri confronti per danni, ivi
inclusi danni generali, speciali, incidentali o conseguenziali, derivanti
dall'utilizzo o dall'incapacità di utilizzo di questo software. Ciò
include, a puro titolo di esempio e senza limitarsi ad essi, la perdita
di dati, l'alterazione involontaria o indesiderata di dati, le perdite
sostenute da voi o da terze parti o un fallimento del software ad
operare con un qualsivoglia altro software. Tale negazione di garanzia
rimane in essere anche se i dententori del copyright, o qualsiasi altra
parte, è stata avvisata della possibilità di tali danneggiamenti.

Se decidete di utilizzare questo software, lo fate a vostro rischio
e pericolo. Se pensate che i termini di questa negazione di garanzia
non si confacciano alle vostre esigenze, o al vostro modo di
considerare un software, o ancora al modo in cui avete sempre trattato
software di terze parti, non usatelo. Se lo usate, accettate espressamente
questa negazione di garanzia e la piena responsabilità per qualsiasi
tipo di danno, di qualsiasi natura, possa derivarne.

=cut
