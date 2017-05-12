package HTML::Form::XSS;

=pod

=head1 NAME

HTML::Form::XSS - Test HTML forms for cross site scripting vulnerabilities.

=head1 SYNOPSIS

	use HTML::Form::XSS;
	use WWW::Mechanize;
	my $mech = WWW::Mechanize->new();
	my $checker = HTML::Form::XSS->new($mech, config => '../root/config.xml');
	$mech->get("http://www.site.com/pagewithform.html");
	my @forms = $mech->forms();
	foreach my $form (@forms){
		my @results = $checker->do_audit($form);
		foreach my $result (@results){
			if($result->vulnerable()){
				my $example = $result->example();
				print "Example of vulnerable URL: $example\n";
				last;
			}
		}
	}

=head1 DESCRIPTION

Provides a simple way to test HTML forms for cross site scripting (XSS)
vulnerabilities.

Checks to perform are given in a XML config file with the results of each
test returned.

=head1 METHODS

=cut

use strict;
use warnings;
use XML::Simple;
use HTML::Form::XSS::Result;
use parent qw(HTML::XSSLint);	#we use this module as a base
our $VERSION = 1.00;
my $BROWSER = 'Mozilla/5.0 (compatible, MSIE 11, Windows NT 6.3; Trident/7.0;  rv:11.0) like Gecko';	#emulate MS IE
###################################

=pod

=head2 new()

	my $mech = WWW::Mechanize->new();
	my $checker = HTML::Form::XSS->new($mech, config => '../root/config.xml');

Creates a new HTML::Form::XSS object using two required parameters. Firstly a 
<WWW::Mechanize> or compatible object, secondly the path to the XML config file.

Please see the example config.xml included in this distribution for details.

=cut

###################################
sub new{
	my($class, $mech, %params) = @_;
	if($mech){	#we need this someday
		if(defined($params{'config'})){	#how can we setup without this
			my $self = {
				'_mech' => $mech,
				'_configFile' => $params{'config'}
			};
			bless $self, $class;
			$self->_loadConfig();
			return $self;
		}
		else{
			die("No Config file option given");
		}
	}
	else{
		die("No WWW::Mechanize compatible object given");
	}
	return undef;
}
###################################
sub make_params {	#passing a check value here, so we can do many checks
	my($self, $check, @inputs) = @_;
	my %params;
	foreach my $input (@inputs){
		if(defined($input->name()) && length($input->name())){
			my $value = $self->random_string();
			$params{$input->name()} = $check . $value;    		
		}
	}
	return \%params;
}
###################################

=pod

=head2 do_audit()

	my @results = $checker->do_audit($form);

Using the provided <HTML::Form> object the form is tested for all the
XSS attacks in the XML config file.

An array of <HTML::Form::XSS::Result> objects are returned, one for
each check.

=cut

#######################################################
sub do_audit {	#we do many checks here not just one
	my($self, $form) = @_;
	my @results;
	print "Checking...\n";
	foreach my $check ($self->_getChecks()){
		my $params = $self->make_params($check, $form->inputs);
		my $request = $self->fillin_and_click($form, $params);
		$request->header('User-Agent' => $BROWSER);
		my $response = $self->request($request);
		print "Status: " . $response->code() . "\n";
		$response->is_success or die("Can't fetch " . $form->action);	
		my @names = $self->compare($response->content, $params);
		my $result = HTML::Form::XSS::Result->new(	#using are modified result class
			form => $form,
			names => \@names,
			check => $check
		);
		push(@results, $result);
	}
	print "\n";
	return @results;
}
###################################
sub compare{	#we need to make the patterns regex safe
	my($self, $html, $params) = @_;
	my @names;
	foreach my $param (keys(%{$params})){
		my $pattern = $self->_makeRegexpSafe($params->{$param});
		if($html =~ m/$pattern/){
			push(@names, $param);
		}
	}
	return @names;
}
###################################
#
#private methods
#
###################################
sub _getChecks{
	my $self = shift;
	my $config = $self->_getConfig();
	my $checks = $config->{'checks'}->{'check'};
	return @{$checks};
}
###################################
sub _getConfigFile{
	my $self = shift;
	return $self->{'_configFile'};
}
###################################
sub _getConfig{
	my $self = shift;
	return $self->{'_config'};
}
###################################
sub _loadConfig{
	my $self = shift;
	my $file = $self->_getConfigFile();
	my $simple = XML::Simple->new();
	my $ref = $simple->XMLin($file);
	$self->{'_config'} = $ref;
	return 1;
}
###################################
sub _makeRegexpSafe{
	my($self, $pattern) = @_;
	$pattern =~ s/([\(\)])/\\$1/g;	#add back slashes where required
	return $pattern;
}
###################################
sub _getMech{
	my $self = shift;
	return $self->{'_mech'};
}
###################################

=pod

=head1 SEE ALSO

L<WWW::Mechanize|WWW::Mechanize>,
L<HTML::Form|HTML::Form>,
L<HTML::XSSLint|HTML::XSSLint>

=head1 AUTHOR

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 COPYRIGHT

Copyright (c) 2016 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

####################################################
return 1;
