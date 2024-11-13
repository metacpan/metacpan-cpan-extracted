See http://ufal.mff.cuni.cz/interset
https://wiki.ufal.ms.mff.cuni.cz/user:zeman:interset
https://metacpan.org/pod/Lingua::Interset

Interset is a means of converting among various tag sets in natural language processing. The core idea is similar to interlingua-based machine translation. Interset defines a set of features that are encoded by the various tag sets. The set of features should be as universal as possible. It does not need to encode everything that is encoded by any tag set but it should encode all information that people may want to access and/or port from one tag set to another. New tag sets are attached by writing a driver for them. Once the driver is ready, you can easily convert tags between the new set and any other set for which you also have a driver. This reusability is an obvious advantage over writing a targeted conversion procedure each time you need to convert between a particular pair of tag sets.

Interset is implemented as a library for Perl and published as Lingua::Interset on CPAN. Writing a conversion script for your particular corpus format is then as easy as reading/writing the data in that format, plus calling e.g. $output_tag = encode('mul::google', decode('en::penn', $input_tag));.

The morphosyntactic features of Interset served as the base for definition of the Universal Features, part of the (new in 2014) Universal Dependencies standard. Interset was also used to create conversion tables from many existing tagsets to the universal POS tags and features. For more details, see https://universaldependencies.org/.
