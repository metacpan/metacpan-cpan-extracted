package Erlang::Interface::Eterm;

use 5.010001;
use strict;
use warnings;
use Erlang::Interface;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Erlang::Interface::Eterm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.
sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        eterm => undef,
    };
    bless $self, $class;
    my $type = shift,
    my $value = shift,

    print "new Eterm\n";
    print $type . "\n";
    if($type == ERL_ATOM){
        print "new atom\n";
        $type = erl_mk_atom($value);
    }else{
        print "bad arguments";
        return undef;
    }
#    $self->{eterm} = tcc_new();
    return $self;
}

sub DESTROY
{
    my $self = shift;
	print "DESTROY Eterm\n";
	if($self->{'eterm'}){
	print "free\n";
        erl_free_term($self->{eterm});
	}
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Erlang::Interface::Eterm - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Erlang::Interface::Eterm;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Erlang::Interface::Eterm, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Tsukasa HAMANO, E<lt>hamano@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tsukasa HAMANO

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
