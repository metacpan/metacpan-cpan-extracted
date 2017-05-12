package Jar::Signer;

use File::Basename;
use File::chdir;

our $VERSION = 0.1;

sub AUTOLOAD{
	my $self = shift;
	my $type = ref $self || die "$self is not an object";
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	if(@_){
		$self->{$name} = shift;
	}
	return $self->{$name};
}

sub new{
	my $self = shift;
	my $class = ref $self || $self;
	my $this = bless {}, $class;
	return $this;
}

sub process{
	my $this = shift;
	my $jar = $this->jar;
	die "Cannot find Jar file $jar\n" unless -e $jar;

	(my $base = $jar) =~ s/\.jar$//;

	my $signed_jar = $this->signed_jar;
	unless( $signed_jar ){
		$this->signed_jar("$base.signed.jar");
	}
	
	my $policy_file = "$base.policy";
	$this->policy_file($policy_file);
		
	if( -e $policy_file ){
		warn sprintf("Adding policy file %s to Jar %s\n",$policy_file,$jar);
		$this->add_policy_file;
	}	
	else {
		my @files = `jar -tf $jar`;
		my $base_policy = basename($policy_file);
		unless( grep( /^${base_policy}$/, @files) ){
			die sprintf("Cannot find policy file '%s' for this Jar file and the Jar does not appear to contain it.\nA policy file for this Jar might look something like:\n\n%s\n"
						, $this->policy_file
						, $this->_demo_policy_file
						);	
		}
	}
	
	$this->generate_keystore unless -e $this->keystore;
	my $alias = $this->alias;
	$this->generate_cert unless -e "$alias.cert";
	$this->generate_fingerprint unless -e "$alias.fingerprint";

	$this->generate_signed_jar;
	return;
}

sub add_policy_file{
	my $this = shift;
	local $CWD = dirname($this->jar);
	my $jar = basename($this->jar);
	my $policy_file = basename($this->policy_file);
	system('jar','-uf',$jar,$policy_file) == 0 or die $!;
	return;
}

sub generate_signed_jar{
	my $this = shift;
	my $jar = $this->jar;
	my $signed_jar = $this->signed_jar;
	my $keystore = $this->keystore;
	my $alias = $this->alias;
	my $base_alias = basename $alias;
	# jar -> signedjar
	@cmd = ( 'jarsigner', '-keystore', $keystore, '-signedjar', $signed_jar, $jar, $base_alias );
	system(@cmd) == 0 or die $!;
	return;
}

sub generate_fingerprint{
	my $this = shift;
	my $keystore = $this->keystore;
	my $alias = $this->alias;
	system("keytool -printcert -file $alias.cert > $alias.fingerprint") == 0 or die $!;
	return;
}

sub generate_cert{
	my $this = shift;
	my $keystore = $this->keystore;
	my $alias = $this->alias;
	my $base_alias = basename $alias;
	@cmd = ( 'keytool', '-export', '-rfc', '-keystore', $keystore, '-alias', $base_alias, '-file', "$alias.cert" );
	system(@cmd) == 0 or die $!;
	return;
}

sub generate_keystore{
	my $this = shift;
	my $alias = $this->alias;
	my $base_alias = basename $alias;
	my $keystore = $this->keystore;
	my $dname = $this->dname;
	my @cmd = ( 'keytool', '-genkey', '-alias', $base_alias, '-keystore', $keystore, '-dname', $dname );
	system(@cmd) == 0 or die $!;
	return;
}

sub _demo_policy_file{
	my $this = shift;
	my $signed_jar = basename( $this->signed_jar );
	my $keystore = basename( $this->keystore );
	my $policy = <<"EOF";
keystore "file:$keystore";

grant signedBy "$keystore",  codeBase "http://host/path/to/$signed_jar" {
  permission java.security.AllPermission;
  permission java.io.FilePermission "<<ALL FILES>>", "read, write, delete";
  permission java.lang.RuntimePermission "createClassLoader";
};

grant signedBy "$keystore",  codeBase "file:$signed_jar" {
  permission java.security.AllPermission;
  permission java.io.FilePermission "<<ALL FILES>>", "read, write, delete";
  permission java.lang.RuntimePermission "createClassLoader";
};
EOF
	return $policy;
}

1;

__END__

=head1 NAME

Jar::Signer - Ease the process of creating a signed Jar file.

=head1 SYNOPSIS

# using FindBin is just a suggestion.

use FindBin qw( $RealBin );

use Jar::Signer;

my $signer = Jar::Signer->new;

# location of the keystore, created if needed.

$signer->keystore("$RealBin/MyKeyStore");

# dname properties of the certificate.

$signer->dname("CN=Mark Southern, O=My Corporation, L=My State, C=USA"); 

# name for .fingerprint and ..cert files, created if needed.

$signer->alias("$RealBin/MyCert");

# the Jar file that we want to sign.

$signer->jar(shift);

# if signed_jar is undefined then the default is basename.signed.jar where basename is the basename of the Jar file.

$signer->signed_jar(shift); 

# create the signed Jar.

$signer->process; 

=head1 DESCRIPTION

This module, and the script that uses it make it a lot simpler to generate 
signed Jar files for use in Java applets etc. It steps through all the needed 
jar, jarsigner and keytool command lines.

=head1 METHODS

jar

=over

Sets/returns the name of the jar file to sign

=back

signed_jar

=over

Sets/returns the name of the signed Jar file to create. if this is undefined 
then the default is basename.signed.jar where basename is the basename of the 
Jar file.

=back

keystore

=over

Sets/returns the name of the key store to use.

=back

alias

=over

Sets/returns the base name for the .cert and .fingerprint files to use

=back

process

=over

The method that scripts everything together. You do not need to call any of 
the methods below as 'process' does this for you.

First the existance of the Jar file and the Keystore, certificate and 
fingerprint files are checked for with the latter three being created as 
needed. Then the policy file is checked for and added to the Jar. The jar is 
then signed.

=back

add_policy_file

=over

Adds the policy file to the Jar. Normally you do not need to call this. It is 
scripted by the 'process' method.

=back

generate_signed_jar

=over

Generates the signed Jar file. Normally you do not need to call this. It is 
scripted by the 'process' method.

=back

generate_fingerprint

=over

Generates a .fingerprint file. Normally you do not need to call this. It is 
scripted by the 'process' method.

=back

generate_cert

=over

Generates a .cert file. Normally you do not need to call this. It is 
scripted by the 'process' method.
generate_keystore

=head1 SEE ALSO

http://java.sun.com/security/signExample12/

=head1 BUGS

Please report them!

=head1 TODO

You are still required to type in a password where required. It would be nice 
if this were set up as a property too.

The jarsigner.pl script could do with a lot of beefing up.

=head1 AUTHOR

Mark Southern (msouthern@exsar.com)

=head1 COPYRIGHT

Copyright (c) 2003, ExSAR Corporation. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html)

=cut
