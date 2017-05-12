use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'MIME::Base64::URLSafe',
	      VERSION_FROM => 'lib/MIME/Base64/URLSafe.pm',
	      PREREQ_PM => { MIME::Base64 => 0 },
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM => 'lib/MIME/Base64/URLSafe.pm',
		AUTHOR => 'Kazuho Oku <kazuho ___at___ labs.cybozu.co.jp>') :
	       ()),
	      );
