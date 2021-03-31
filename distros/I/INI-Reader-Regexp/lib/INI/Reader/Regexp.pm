package INI::Reader::Regexp;

use Mouse;
use utf8;
use Kavorka;
use Regexp::Grammars;

our $VERSION = '0.04';


my %hash;
my @arr;
my %pairs;

method AST::INI::X() {
    for my $element ( @{ $self->{Section} } ) {
        $element->X();
    }
    return \%hash;
}

method AST::Section::X() {
    @arr = ();
    %pairs = ();
    my $head = $self->{Header}->X();
    my %pairs = $self->{Block}->X();
    $hash{$head} = \%pairs;
}

method AST::Header::X(){
    return $self->{Head}->X();
}

method AST::Block::X(){
    for my $element ( @{ $self->{statement} } ) {
         $element->X();
    }
    return @arr;
}

method AST::Head::X() {
    return $self->{''};
}

method AST::statement::X() {
    (        $self->{Comment}
          || $self->{Key_Value} )->X();
}

method AST::Comment::X() {
    $self->{Sign}->X();
    $self->{Commentstring}->X();
}

method AST::Key_Value::X() {
    my $k = $self->{Key}->X();
    my $sep = $self->{Sep}->X();
    my $v = $self->{Value}->X();
    if( $sep eq '=') {
        push @arr, ($k, $v);
    }
}

method AST::Sign::X() {
    $self->{''};
}

method AST::Commentstring::X() {
    $self->{''};
}

method AST::Key::X() {
    return $self->{''};
}

method AST::Sep::X() {
    return $self->{''};
}

method AST::Value::X() {
    return $self->{''};
}

my $parser = qr {
    <nocontext:>
    #<debug: on>

    <INI>
    <objrule:  AST::INI>                <[Section]>+

    <objrule:  AST::Section>            <ws: (\s++)*> <Header> <Block>

    <objrule:  AST::Header>             \[ <Head> \]

    <objrule:  AST::Block>              <[statement]>+
    <objrule:  AST::statement>          <Comment> | <Key_Value>

    <objrule:  AST::Key_Value>          <Key> \s* <Sep> \s* <Value> \n+

    <objrule:  AST::Comment>            <Sign> <Commentstring> \n+

    <objtoken: AST::Sign>               [;#]
    <objtoken: AST::Head>               .*?
    <objtoken: AST::Key>                \w+
    <objtoken: AST::Sep>                \=
    <objtoken: AST::Value>              .*?
    <objtoken: AST::Commentstring>      .*?
}xms;


method INI_parse( $string ) {
    if( $string =~ $parser ) {
        $/{INI}->X();
    }
}



1;
__END__
=encoding utf-8

=head1 NAME

INI::Reader::Regexp - INI Parser

=head1 SYNOPSIS

	ini_string contains:


	[Settings]
	#======================================================================
	# Set detailed log for additional debugging info
	DetailedLog=1
	RunStatus=1
	StatusPort=6090
	StatusRefresh=10
	Archive=1
	# Sets the location of the MV_FTP log file
	LogFile=/opt/ecs/mvuser/MV_IPTel/log/MV_IPTel.log
	#======================================================================
	Version=0.9 Build 4 Created July 11 2004 14:00
	ServerName=Unknown


	[FTP]
	#======================================================================
	# set the FTP server active
	RunFTP=1
	# defines the FTP control port
	FTPPort=21
	# defines the FTP data port
	FTPDataPort=20
	# Sets the location of the FTP data directory to catch terminal backups
	FTPDir=/opt/ecs/mvuser/MV_IPTel/data/FTPdata
	# FTP Timeout (secs)
	FTP_TimeOut=5
	# Enable SuperUser
	EnableSU=1
	# set the SuperUser Name
	SUUserName=mvuser
	# set the SuperUser Password
	SUPassword=Avaya
	#
	#======================================================================


=head1 DESCRIPTION

	use strict;
	use warnings;
	use utf8;
        use INI::Reader::Regexp;

        my $ini_parser = INI::Reader::Regexp->new();
	my $hash = $ini_parser->INI_parse($ini_string);

	print $hash->{Settings}->{ServerName};


=head1 AUTHOR

Rajkumar Reddy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
