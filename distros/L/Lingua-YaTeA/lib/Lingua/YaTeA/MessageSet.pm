package Lingua::YaTeA::MessageSet;
use strict;
use warnings;

use Lingua::YaTeA::Message;
use Data::Dumper;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$file,$language) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{MESSAGES} = {};
    $this->loadMessages($file,$language);
    return $this;
}

sub loadMessages
{
    my ($this,$file,$language) = @_;
    my $path = $file->getPath;
    my $fh = FileHandle->new("<$path");
    my $line;
    my $line_counter = 0;
    my $message;
    my $option;
  
    
    while ($line= $fh->getline)
    {
	$line_counter++;
	if ($line =~ /^([^\s]+) = \"(.+)\"\s*$/)
	{
	    $message = Lingua::YaTeA::Message->new($1,$2,$language);
	    $this->addMessage($message);	    
	}
	else
	{
	    if($line !~ /^\s*$/)
	    {
		die "ill-formed message in file:" .$file->getPath .  " line " . $line_counter . "\n";
	    }
	}
    }
}

sub addMessage
{
    my ($this,$message) = @_;
    $this->{MESSAGES}->{$message->getName} = $message;
}


sub getMessage
{
    my ($this,$name) = @_;
    return $this->getMessages->{$name};
}

sub getMessages
{
    my ($this) = @_;
    return $this->{MESSAGES};
}
1;

__END__

=head1 NAME

Lingua::YaTeA::MessageSet - Perl extension for message set

=head1 SYNOPSIS

  use Lingua::YaTeA::MessageSet;
  Lingua::YaTeA::MessageSet->new($file, $language);

=head1 DESCRIPTION

The module is dedicated to the management of the message set acccoding
to the language. Messages are stored in the C<MESSAGES> field, a
hashtables.

=head1 METHODS

=head2 new()

    new($file, $language);

The method creates a new message set for the language C<$language> and
loads the messages stored in the file C<$file>.

=head2 loadMessages()

    loadMessages($file, $language);


the method loads the messages stored in the file C<$file>, for the
language C<$language>.

=head2 addMessage()

    addMessage($message);

The method adds a message in the message set. 

=head2 getMessage()

    getMessage($name);

The method returns the message named C<$name>.

=head2 getMessages()

    getMessages();

The method returns the reference to the hashtable containing the messages.

=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
