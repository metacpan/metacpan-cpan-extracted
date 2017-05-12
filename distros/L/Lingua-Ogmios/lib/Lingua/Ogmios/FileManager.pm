package Lingua::Ogmios::FileManager;

use strict;
use warnings;

use File::MMagic;
use Lingua::Ogmios::Annotations;


sub new {
    my ($class, $MNFile) = @_;

    my $FM = {
	'MagicNumberFilename' => $MNFile,
	'MagicNumbers' => undef,
    };

    bless $FM, $class;

    $FM->_load_MagicNumber;

    return($FM);
}

sub getMagicNumberFilename {
    my ($self) = @_;

    return($self->{'MagicNumberFilename'});
}

sub setMagicNumberFilename {
    my ($self, $filename) = @_;

    $self->{'MagicNumberFilename'} = $filename;
}



sub _load_MagicNumber
{
    my $self = shift;
    my $MNFile = $self->getMagicNumberFilename;

    my $mm = new File::MMagic; # use internal magic file

    print STDERR "Loading complementary magic number ... ";
    
    if (open FILEM, $MNFile) {

	my $line;
	
	while($line = <FILEM>) {
	    chomp $line;
	    $line =~ s/\s*\#.*//;
	    $line =~ s/^\s*//;
	    
	    if ($line ne "") {
		$mm->addMagicEntry($line);
	    }
	}
	print STDERR "done\n";

    } else {
	warn "$MNFile: no such file or directory\n";
        warn "No more Magic Number definition is loaded\n";

    }
    $self->{'MagicNumbers'} = $mm;
    
    return($mm);
}

sub getType {
    my ($self, $file) = @_;

    my $xmlns;

    if (-d $file) {
	return('directory');
    }
    if (-f $file) {

	my $mm = $self->{'MagicNumbers'};

	print STDERR "Determining the type of the file " . $file . ": ";
	
	my $type = $mm->checktype_filename($file);

	if ($file =~ /.ppt$/i) {
	    $type = "application/powerpoint";
	    warn "Getting the type thanks to the extension\n";
	}
	if ($file =~ /.xls$/i) {
	    $type = "application/vnd.ms-excel";
	    warn "Getting the type thanks to the extension\n";
	}
	# if msword may be it should be relevant to check the extension, to better determine the type
	$type =~ s/;.*//;
	if (($type eq "message/rfc822") || ($file =~ /^x-system\/x-unix;/)) {
	    if ($file =~ /.tex$/i) {
		$type = "text/x-tex";
		warn "Getting the type thanks to the extension\n";
	    }
	}
	if ($type eq 'text/xml') {
	    $xmlns = Lingua::Ogmios::Annotations::getNamespace($file);
	    $type .= " ns=$xmlns";
	}
	print STDERR "Type file: $type\n";
	return($type);
	
    } else {
	warn "Unknown type\n";
	return('unknown');
    }

}


sub convert {

}

sub XMLconvert {

}

1;

__END__

=head1 NAME

Lingua::Ogmios::FileManager - Perl extension for managing the files

=head1 SYNOPSIS

use Lingua::Ogmios::???;

my $filemanager = Lingua::Ogmios::???::new();


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

