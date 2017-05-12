package Mac::Glue::Apps::AddressBookExport;

use strict;
use Encode qw(decode);
use Carp;
use Template;
use Text::vCard::Addressbook;

our $VERSION = 0.2;

my $is_mac = 0;
$is_mac = 1 if $^O eq 'darwin';

require Mac::Glue if $is_mac;

=head1 NAME

Mac::Glue::Apps::AddressBookExport - Export from Address Book and publish

=head1 SYNOPSIS

  use Mac::Glue::Apps::AddressBookExport;
  my $exporter = Mac::Glue::Apps::AddressBookExport->new({
    'glue_name'       => 'Address Book',
    'template_dir'    => '/path/to/template_dir/',
    'out_dir'         => '/where/to/write/out/pages_dir/',
    'skip_with_image' => 1,
  });
  $exporter->export_address_book();

This will generate an index page (with names and phone numbers)
in your 'out_dir'. It will also create 'out_dir/people/<letter>.html'
which will be all those people who's name starts with that letter,
showing name, phone numbers, emails and addresses.
 
=head1 DESCRIPTION

This package uses Mac::Glue to export all vCards from your
Apple Address Book. I can write this file to disk, or process
the results using Text::vCard and Template Toolkit to generate
web pages.

=head2 new()

  my $exporter = Mac::Glue::Apps::AddressBookExport->new({
    'glue_name'       => 'Address Book',
    'template_dir'    => '/path/to/template_dir/',
    'out_dir'         => '/where/to/write/out/pages_dir/',
    'skip_with_image' => 1,
  }); 

All options can be set here, rather than having to be
passed to each method, but equally options can be set
as each method is called (overwriting what is already in
the object). This constructor doesn't actually do anything
other than store the options submitted to it and return
the object.

See the examples directory for template examples.

=cut

sub new {
        my ($class,$self) = @_;
	
	# Looks like they didn't supply params
	$self = {} unless $self && ref($self) eq 'HASH';
	bless($self, $class);	
	return $self;
}

=head2 export_address_book()

 $exporter->export_address_book({
	'glue_name' 	=> 'Address Book', # Default

	# Optional dump of vcard file
	'out_file' => '/full/path/to/outfile.vcf',
	
	# Generate templates
 	'template_dir' => '/path/to/template_dir/',
	'out_dir' => '/where/to/write/out/pages_dir/',
});

The out_file will be version 3.0 of the vCard spec, you
can use Text::vCard::Addressbook to parse this.

If 'template_dir' and 'out_dir' are specified then the
generate_web_pages() will be called after the address book
has been exported.

=cut

sub export_address_book {
	my $self = shift;
	$self->_pop_from_conf(shift);
	
	croak "You can not export unless running on a mac" unless $is_mac;
	
	# Get from address book
	$self->get_vcards_from_addressbook();

	if(defined $self->{out_file}) {
		# User wanted to write to disk		
		open(FH,'>' . $self->{out_file}) or carp "Could not print $!";
		print FH $self->{vcards};
		close(FH);
	}
	# See if they want to process locally
	if(defined $self->{template_root} && defined $self->{out_dir}) {
		$self->generate_web_pages();
	}
}

=head2 generate_web_pages()

  $exporter->generate_web_pages({
    'template_root' => '/path/to/template/dir',
    'out_dir'       => '/path/results/printed/to',
    'vcards'        => $vcard_data,
  });

This method is called automatically from export_address_book()
if 'template_root' and 'out_dir' have been specified.

The template_dir should contain 'index.html' and 'by_name.html'
template (see examples directory of this package for a starting point),
but it will check and just not process if they are missing.

'vcards' will have already been populated if export_address_book()
has been called. Alternativly you can supply the vcard data which
is submitted to Text::vCard::Addressbook as source_text.

=cut

sub generate_web_pages {
	my $self = shift;
	$self->_pop_from_conf(shift);

	croak "'template_root' not a directory or does not exist" unless -d $self->{template_root};
	croak "'out_dir' not a directory or does not exist" unless -d $self->{out_dir};
	croak "No 'vcards' data defined" unless defined $self->{vcards};
	
	my %config = (
		INCLUDE_PATH	=> $self->{template_root},
		# Add cache options ?
	);
	my $tt = Template->new(\%config);
	
	# Get the Text::vCard object
	$self->{address_book} = Text::vCard::Addressbook->new({
		 'source_text' => $self->{vcards},
	});

	# Sort
	my $vcards = $self->{address_book}->vcards;
	
	if(-r $self->{template_root} . '/index.html') {
		# use TT for output
		my %vals = (
			'people' => $vcards,
			'first_letter' => \&get_first_letter_from_vcard,
		);
		my $file;
                my $template_response = $tt->process('index.html',\%vals, \$file);
		carp $tt->error if $tt->error;
		open(FH,'>' . $self->{out_dir} . '/index.html');
		print FH $file;
		close(FH);
	}
	if(-r $self->{template_root} . '/by_name.html') {
		# Print each person
		my $people_dir = $self->{out_dir} . '/people';
		mkdir $people_dir unless -d $people_dir;
		
		# sort out who goes where
		my %letters;
		foreach my $vcard (@{$vcards}) {
			my $letter = get_first_letter_from_vcard($vcard);
			unless(defined $letters{$letter}) {
				my @store;
				$letters{$letter} = \@store;
			}
			push(@{$letters{$letter}}, $vcard);
		
		}

		# Generate the pages
		while(my($letter,$vcards) = each %letters) {
			my %vals = (
				'people' => $vcards,
				'letter' => $letter,
				'letters' => \%letters,
				'first_letter' => \&get_first_letter_from_vcard,
			);

			my $file;
			my $template_response = $tt->process('by_name.html',\%vals, \$file);
			carp $tt->error() if $tt->error();
			
			open(FH,">$people_dir/$letter.html") or carp "Could not open file $people_dir/$letter.html $!";
			print FH $file;
			close(FH);
		}
	}
}

=head2 get_vcards_from_addressbook()
	
  my $vcards = $exporter->get_vcards_from_addressbook({
    'skip_with_image' => 1,
    'glue_name'       => 'Address Book',
  });

This is the method which calls Mac::Glue and extracts
the vcard information from Apples Address Book.

'skip_with_image' is there so that and person with an
image associated can be skipped on the export. This is because
Text::vCard can not support it currently.

The glue_name defaults to 'Address Book', but as you can
set it when you create your glue (see Mac::Glue) this option
allows you to overwrite the default.

=cut

sub get_vcards_from_addressbook {
	croak "You can not export from Apple Address Book unless on a mac" unless $is_mac;
	my $self = shift;
	$self->_pop_from_conf(shift);
	
	my $glue_name = $self->{'glue_name'} || 'Address Book';

	my $address = new Mac::Glue $glue_name;
	
	# get everyone
	my @people = $address->prop('people')->get;

	my $vcards;
	for my $person (@people) {
		# Loop and get each persons card
		# Skip if they have a photo as Text::vFile::asData can't cope
		next if $person->prop('image')->get && defined $self->{'skip_with_image'};
		$vcards .= $person->prop('vcard')->get;
	}

	$address->quit();

	return $self->{vcards} = $vcards;
}

=head2 get_first_letter_from_vcard()

This is a function, NOT a method.

  my $first_letter = get_first_letter_from_vcard($vcard,'fullname');

This function can take two arguments. The First must be a Text::vCard
object. The second is optional (defaulting to 'fullname') which is
the method to call on the object. The first letter of the return
value from the method is then returned upper cased.

This is used to sort which page each person is put on and in the
template to generate the links for each person and which letters
are active.
  
=cut

sub get_first_letter_from_vcard {
	my $vcard = shift;
	return '?' unless $vcard;
	
	my $method = shift || 'fullname';
	
	my $name = $vcard->$method() || 'x';
	my $l = '';
	$l = decode('utf-8',substr($name,0,1)) if $name ne '';
	if($l eq '') {
		$l = 'other';
	}
	return uc($l);
}

# So they can use each method seperatly, or from previous configs
sub _pop_from_conf {
	my $self = shift;
	
	if(my $conf = shift) {
		# Take everything out of conf and stick in self
		map { $self->{$_} = $conf->{$_} } keys %{$conf};
	}
}

=head1 NOTES

One could extend this package to upload the vCard file to
a server and have that then generate webpages, but for now
that's an exercise for the user! I'm just going to rsync
my pages up. If anyone wants to extend this to inserting info
into a DB or something else please let me know.

=head1 AUTHOR

Leo Lapworth, LLAP@cuckoo.org

=head1 COPYRIGHT

Copyright (c) 2005 Leo Lapworth. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Mac::Glue Text::vCard Template

=cut

1;
