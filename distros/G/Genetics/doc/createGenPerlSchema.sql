#
# This creates the MySQL schema for storage of Genperl objects
# 

CREATE TABLE Object 
(
  name                  VARCHAR(120) NOT NULL,
  id                    BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
  objType               ENUM("Cluster", "Subject", "Kindred", "Marker", "SNP", "Genotype", "StudyVariable", "Phenotype", "HtMarkerCollection", "Haplotype", "Map", "FrequencySource", "DNASample", "TissueSample") NOT NULL,
  dateCreated           DATE NOT NULL,
  dateModified          TIMESTAMP NOT NULL,
  comment               TEXT NULL,
  url                   TEXT NULL,
  contactID             MEDIUMINT UNSIGNED NULL,
  PRIMARY KEY( id )
);

CREATE TABLE NameAlias 
(
  objID                 BIGINT UNSIGNED NOT NULL,
  name                  VARCHAR(120) NOT NULL,
  contactID             MEDIUMINT UNSIGNED NULL
);

CREATE TABLE Contact 
(
  contactID             MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  addressID             MEDIUMINT UNSIGNED NULL,
  name                  VARCHAR(120) NOT NULL,
  organization          VARCHAR(120) NULL,
  comment               TEXT NULL,
  PRIMARY KEY( contactID ),
  UNIQUE( name )
);

CREATE TABLE Address 
(
  addressID             MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  streetOne             VARCHAR(120) NULL,
  streetTwo             VARCHAR(120) NULL,
  city                  VARCHAR(30) NULL,
  stateProvince         VARCHAR(30) NULL,
  zipPostalCode         VARCHAR(20) NULL,
  country               VARCHAR(30) NULL,
  telephoneNumber       VARCHAR(15) NULL,
  telephoneNumberExtension VARCHAR(8) NULL,
  cellularNumber        VARCHAR(15) NULL,
  faxNumber             VARCHAR(15) NULL,
  emailAddress          VARCHAR(255) NULL,
  preferredContactMethod ENUM("Telephone", "Cell", "Fax", "Email", "SnailMail") NULL,
  PRIMARY KEY( addressID )
);

CREATE TABLE DBXReference 
(
  dbXRefID              MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  objID                 BIGINT UNSIGNED NOT NULL,
  accessionNumber       VARCHAR(32) NOT NULL,
  databaseName          VARCHAR(32) NOT NULL,
  schemaName            VARCHAR(120) NULL,
  comment               TEXT NULL,
  PRIMARY KEY( dbXRefID )
);

CREATE TABLE KeywordType 
(
  keywordTypeID         MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  name                  VARCHAR(120) NOT NULL,
  dataType              ENUM("String", "Number", "Date", "Boolean") NOT NULL,
  description           VARCHAR(255) NULL,
  PRIMARY KEY( keywordTypeID )
);

INSERT INTO KeywordType (keywordTypeID, name, dataType, description) 
	         VALUES (NULL, "ImportID", "String", "Import ID");
INSERT INTO KeywordType (keywordTypeID, name, dataType, description) 
	         VALUES (NULL, "Kindred ImportID", "String", "A Subject's pre-import Kindred reference");
INSERT INTO KeywordType (keywordTypeID, name, dataType, description) 
	         VALUES (NULL, "Mother ImportID", "String", "A Subject's pre-import Mother reference");
INSERT INTO KeywordType (keywordTypeID, name, dataType, description) 
	         VALUES (NULL, "Father ImportID", "String", "A Subject's pre-import Father reference");
INSERT INTO KeywordType (keywordTypeID, name, dataType, description) 
	         VALUES (NULL, "Subjects ImportID", "String", "A Kindred's pre-import Subject references");
INSERT INTO KeywordType (keywordTypeID, name, dataType, description)
	         VALUES (NULL, "Test Data", "Boolean", "Is this made-up test data?");

CREATE TABLE Keyword 
(
  keywordID             BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
  objID                 BIGINT UNSIGNED NOT NULL,
  keywordTypeID         MEDIUMINT UNSIGNED NOT NULL,
  stringValue           VARCHAR(32) NULL,
  numberValue           FLOAT(10,5) NULL,
  dateValue             DATE NULL,
  booleanValue          TINYINT(1) UNSIGNED NULL,
  PRIMARY KEY( keywordID )
);

CREATE TABLE Cluster
(
  clusterID            BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
  clusterType          ENUM("Mixed", "Subject", "Kindred", "Marker", "SNP", "Genotype", "StudyVariable", "Phenotype", "HaplotypeMarkerCollection", "Haplotype", "Map", "FrequencySource", "DNASample", "TissueSample") NOT NULL,
  PRIMARY KEY( clusterID )
);

CREATE TABLE ClusterContents 
(
  clusterID             BIGINT UNSIGNED NOT NULL,
  objID                 BIGINT UNSIGNED NOT NULL,
  INDEX( clusterID ),
  INDEX( objID )
);

CREATE TABLE Organism 
(
  organismID            MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  genusSpecies          VARCHAR(255) NOT NULL,
  subspecies            VARCHAR(120) NULL,
  strain                VARCHAR(120) NULL,
  PRIMARY KEY( organismID ),
  UNIQUE( genusSpecies, subspecies, strain )
);

CREATE TABLE Subject 
(
  subjectID             BIGINT UNSIGNED NOT NULL,
  organismID            MEDIUMINT UNSIGNED NULL,
  kindredID             MEDIUMINT UNSIGNED NULL,
  motherID              BIGINT UNSIGNED NULL,
  fatherID              BIGINT UNSIGNED NULL,
  gender                ENUM("Unknown", "Male", "Female", "Both") NOT NULL,
  dateOfBirth           DATE NULL,
  dateOfDeath           DATE NULL,
  isProband             TINYINT(1) NOT NULL,
  PRIMARY KEY( subjectID )
);

CREATE TABLE Kindred 
(
  kindredID             BIGINT UNSIGNED NOT NULL,
  isDerived             TINYINT(1) NOT NULL,
  parentID              BIGINT UNSIGNED NULL,
  PRIMARY KEY( kindredID )
);

CREATE TABLE KindredSubject 
(
  kindredID             BIGINT UNSIGNED NOT NULL,
  subjectID             BIGINT UNSIGNED NOT NULL
);

CREATE TABLE SequenceObject
(
  seqObjectID           BIGINT UNSIGNED NOT NULL,
  chromosome            VARCHAR(8) NULL,
  organismID            MEDIUMINT UNSIGNED NULL,
  sequenceID            MEDIUMINT UNSIGNED NULL,
  malePloidy            TINYINT(2) NULL,
  femalePloidy          TINYINT(2) NULL,
  PRIMARY KEY( seqObjectID )
);

CREATE TABLE Sequence
(
  sequenceID            MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  sequence              TEXT NOT NULL,
  length                MEDIUMINT UNSIGNED NULL,
  lengthUnits           ENUM("bp", "Kb", "Mb") NULL,
  PRIMARY KEY( sequenceID )
);

CREATE TABLE ISCNMapLocation
(
  iscnMapLocID          MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  chrNumber             VARCHAR(8) NOT NULL,
  chrArm                VARCHAR(8) NULL,
  band                  VARCHAR(16) NULL,
  bandingMethod         VARCHAR(32) NULL,
  PRIMARY KEY( iscnMapLocID )
);

CREATE TABLE SeqObjISCN 
(
  seqObjectID           BIGINT UNSIGNED NOT NULL,
  iscnMapLocID          MEDIUMINT UNSIGNED NOT NULL
);

CREATE TABLE Marker
(
  markerID              BIGINT UNSIGNED NOT NULL,
  polymorphismType      ENUM("Repeat", "RestrictionSite", "InsertionDeletion", "Other") NULL,
  polymorphismIndex1	MEDIUMINT UNSIGNED NULL,
  polymorphismIndex2	MEDIUMINT UNSIGNED NULL,
  repeatSequence        VARCHAR(8) NULL,
  PRIMARY KEY( markerID )
);

CREATE TABLE SNP
(
  snpID                 BIGINT UNSIGNED NOT NULL,
  snpType               ENUM("Substitution", "Insertion", "Deletion", "InDel", "Unknown") NOT NULL,
  functionClass         ENUM("Noncoding", "Coding", "Synonymous", "Nonsynonymous", "5UTR", "3UTR", "Intron", "SpliceSite", "Intergenic", "Unknown") NOT NULL,
  snpIndex              MEDIUMINT UNSIGNED NULL,
  isConfirmed           TINYINT(1) NOT NULL,
  confirmMethod		VARCHAR(255) NULL,
  PRIMARY KEY( snpID )
);

CREATE TABLE Allele 
(
  alleleID              MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  poID                  BIGINT UNSIGNED NOT NULL,
  name                  VARCHAR(4) NOT NULL,
  type                  ENUM("Code", "Size", "RepeatNumber", "Nucleotide", "Undefined") NOT NULL,
  PRIMARY KEY( alleleID ),
  UNIQUE INDEX poAllele ( poID, name, type)
);

CREATE TABLE Genotype
(
  gtID                  BIGINT UNSIGNED NOT NULL,
  subjectID             BIGINT UNSIGNED NOT NULL,
  poID                  BIGINT UNSIGNED NOT NULL,
  isActive              TINYINT(1) NOT NULL,
  icResult              ENUM("Pass", "Fail", "Ambiguous", "Unknown") NULL,
  dateCollected         DATE NULL,
  PRIMARY KEY( gtID ),
  INDEX( subjectID ),
  INDEX( poID )
);

CREATE TABLE AlleleCall
(
  alleleCallID          BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
  gtID                  BIGINT UNSIGNED NOT NULL,
  alleleID              MEDIUMINT UNSIGNED NOT NULL,
  sortOrder             TINYINT(2) NOT NULL,
  phase                 ENUM("Unknown", "Maternal", "Paternal") NOT NULL,
  PRIMARY KEY( alleleCallID ),
  INDEX gtIDX( gtID )
);

CREATE TABLE StudyVariable 
(
  studyVariableID       BIGINT UNSIGNED NOT NULL,
  category              ENUM("Trait", "StaticAffectionStatus", "StaticLiabilityClass", "DynamicAffectionStatus", "Environment", "Treatment") NOT NULL,
  format                ENUM("Number", "Code", "Date", "DerivedNumber", "DerivedCode") NOT NULL,
  isXLinked             TINYINT(1) NOT NULL,
  description           VARCHAR(255) NULL,
  numberLowerBound      DECIMAL(12,5) NULL,
  numberUpperBound      DECIMAL(12,5) NULL,
  dateLowerBound        DATE NULL,
  dateUpperBound        DATE NULL,
  PRIMARY KEY( studyVariableID )
);

CREATE TABLE CodeDerivation
(
  codeDerivationID      MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  studyVariableID       BIGINT UNSIGNED NOT NULL,
  code                  TINYINT(2) NOT NULL,
  description           VARCHAR(255) NULL,
  formula               TEXT NULL,
  PRIMARY KEY( codeDerivationID ),
  INDEX( studyVariableID )
);

CREATE TABLE AffectionStatusDefinition 
(
  asDefID               MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  studyVariableID       BIGINT UNSIGNED NOT NULL,
  name                  VARCHAR(120) NOT NULL,
  diseaseAlleleFreq     DECIMAL(7,6) NOT NULL,
  pen11                 DECIMAL(7,6) NOT NULL,
  pen12                 DECIMAL(7,6) NOT NULL,
  pen22                 DECIMAL(7,6) NOT NULL,
  malePen1              DECIMAL(7,6) NULL,
  malePen2              DECIMAL(7,6) NULL,
  PRIMARY KEY( asDefID ), 
  INDEX( studyVariableID )
);

CREATE TABLE AffectionStatusElement 
(
  asElementID           MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  asDefID               MEDIUMINT UNSIGNED NOT NULL,
  code                  TINYINT(1) NOT NULL,
  type                  ENUM("Unknown", "Unaffected", "Affected") NOT NULL,
  formula               TEXT NULL,
  PRIMARY KEY( asElementID ),
  INDEX( asDefID )
);

CREATE TABLE StaticLCPenetrance 
(
  cdID                  MEDIUMINT UNSIGNED NOT NULL,
  pen11                 DECIMAL(7,6) NOT NULL,
  pen12                 DECIMAL(7,6) NOT NULL,
  pen22                 DECIMAL(7,6) NOT NULL,
  malePen1              DECIMAL(7,6) NULL,
  malePen2              DECIMAL(7,6) NULL,
  PRIMARY KEY( cdID ) 
);

CREATE TABLE LiabilityClassDefinition 
(
  lcDefID               MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  studyVariableID       BIGINT UNSIGNED NOT NULL,
  name                  VARCHAR(120) NOT NULL,
  PRIMARY KEY( lcDefID ),
  INDEX( studyVariableID )
);

CREATE TABLE LiabilityClass
(
  lcID                  MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  lcDefID               MEDIUMINT UNSIGNED NOT NULL,
  code                  TINYINT(2) NOT NULL,
  description           VARCHAR(255) NULL,
  pen11                 DECIMAL(7,6) NOT NULL,
  pen12                 DECIMAL(7,6) NOT NULL,
  pen22                 DECIMAL(7,6) NOT NULL,
  malePen1              DECIMAL(7,6) NULL,
  malePen2              DECIMAL(7,6) NULL,
  formula               TEXT NULL,
  PRIMARY KEY( lcID ),
  INDEX( lcDefID )
);

CREATE TABLE Phenotype
(
  ptID                  BIGINT UNSIGNED NOT NULL,
  subjectID             BIGINT UNSIGNED NOT NULL,
  svID                  BIGINT UNSIGNED NOT NULL,
  numberValue           DECIMAL(12,5) NULL,
  codeValue             TINYINT(2) NULL,
  dateValue             DATE NULL,
  isActive              TINYINT(1) NOT NULL,
  dateCollected         DATE NULL,
  PRIMARY KEY( ptID ),
  INDEX( subjectID ),
  INDEX( svID )
);

CREATE TABLE FreqSourceObsFrequency
(
  freqSourceID          BIGINT UNSIGNED NOT NULL,
  obsFreqID             MEDIUMINT UNSIGNED NOT NULL,
  INDEX( freqSourceID )
);

CREATE TABLE ObsFrequency
(
  obsFreqID             MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  type                  ENUM("Allele", "Ht") NOT NULL,
  alleleID              MEDIUMINT UNSIGNED NULL,
  htID                  MEDIUMINT UNSIGNED NULL,
  frequency             FLOAT NOT NULL,
  PRIMARY KEY( obsFreqID )
);

CREATE TABLE HtMarkerCollection 
(
  hmcID                 BIGINT UNSIGNED NOT NULL,
  distanceUnits         ENUM("cM", "bp", "Kb", "Mb", "cR", "cR3000", "cR10000", "Theta") NOT NULL,
  PRIMARY KEY( hmcID )
);

CREATE TABLE HMCPolyObj 
(
  hmcID                 BIGINT UNSIGNED NOT NULL,
  poID                  BIGINT UNSIGNED NOT NULL,
  sortOrder             TINYINT(2) NOT NULL,
  distance              DECIMAL(10,5) NULL,
  INDEX( hmcID )
);

CREATE TABLE Haplotype 
(
  haplotypeID           BIGINT UNSIGNED NOT NULL,
  hmcID                 BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY( haplotypeID ),
  INDEX( hmcID )
);

CREATE TABLE HaplotypeAllele 
(
  haplotypeID           BIGINT UNSIGNED NOT NULL,
  alleleID              MEDIUMINT UNSIGNED NOT NULL,
  sortOrder             TINYINT(2) NOT NULL,
  INDEX( haplotypeID )
);

CREATE TABLE SubjectHaplotype 
(
  haplotypeID          BIGINT UNSIGNED NOT NULL,
  subjectID            BIGINT UNSIGNED NOT NULL,
  phase                ENUM("Unknown", "Maternal", "Paternal") NOT NULL,
  INDEX( haplotypeID ),
  INDEX( subjectID )
);

CREATE TABLE Sample 
(
  sampleID              BIGINT UNSIGNED NOT NULL,
  type                  ENUM("DNA", "Tissue") NOT NULL,
  dateCollected         DATE NULL,
  PRIMARY KEY( sampleID )
);

CREATE TABLE SubjectSample 
(
  subjectID             BIGINT UNSIGNED NOT NULL,
  sampleID              BIGINT UNSIGNED NOT NULL,
  INDEX( sampleID ),
  INDEX( subjectID )
);

CREATE TABLE SampleGenotype 
(
  sampleID              BIGINT UNSIGNED NOT NULL,
  gtID                  BIGINT UNSIGNED NOT NULL,
  INDEX( sampleID ),
  INDEX( gtID )
);

CREATE TABLE DNASample 
(
  dnaSampleID           BIGINT UNSIGNED NOT NULL,
  amount                DECIMAL(6,3) NULL,
  amountUnits           ENUM("g", "mg", "ug", "ng") NULL,
  concentration         DECIMAL(6,3) NULL,
  concUnits             ENUM("mg/ml", "ug/ml", "ug/ul", "ng/ul") NULL,
  PRIMARY KEY( dnaSampleID )
);

CREATE TABLE TissueSample 
(
  tissueSampleID        BIGINT UNSIGNED NOT NULL,
  tissue                VARCHAR(120) NOT NULL,
  amount                DECIMAL(6,3) NULL,
  amountUnits           ENUM("g", "mg", "ug", "ng") NULL,
  PRIMARY KEY( tissueSampleID )
);

CREATE TABLE TissueDNASample 
(
  tissueSampleID        BIGINT UNSIGNED NOT NULL,
  dnaSampleID           BIGINT UNSIGNED NOT NULL,
  INDEX( tissueSampleID ),
  INDEX( dnaSampleID )
);

CREATE TABLE Map
(
  mapID                 BIGINT UNSIGNED NOT NULL,
  chromosome            VARCHAR(8) NULL,
  organismID            MEDIUMINT UNSIGNED NULL,
  orderingMethod        ENUM("Relative", "Global") NOT NULL,
  distanceUnits         ENUM("cM", "bp", "Kb", "Mb", "cR", "cR3000", "cR10000", "Theta") NOT NULL,
  PRIMARY KEY( mapID )
);

CREATE TABLE OrderedMapElement
(
  omeID                 MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  mapID                 BIGINT UNSIGNED NOT NULL,
  soID                  BIGINT UNSIGNED NOT NULL,
  sortOrder             TINYINT(2) NOT NULL,
  name                  VARCHAR(120) NOT NULL,
  distance              DECIMAL(10,5) NULL,
  comment               TEXT NULL,
  PRIMARY KEY( omeID )
);

CREATE TABLE UnorderedMapElement
(
  umeID                 MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  mapID                 BIGINT UNSIGNED NOT NULL,
  soID                  BIGINT UNSIGNED NOT NULL,
  name                  VARCHAR(120) NOT NULL,
  comment               TEXT NULL,
  PRIMARY KEY( umeID )
);

CREATE TABLE AssayAttribute
(
  attrID                MEDIUMINT UNSIGNED AUTO_INCREMENT NOT NULL,
  name                  VARCHAR(120) NOT NULL,
  dataType              ENUM("String", "Number", "Date", "Boolean") NOT NULL,
  description           VARCHAR(255) NULL,
  PRIMARY KEY( attrID )
);

CREATE TABLE AttributeValue
(
  attrValueID           BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
  objID                 BIGINT UNSIGNED NULL,
  alleleCallID          BIGINT UNSIGNED NULL,
  attrID                MEDIUMINT UNSIGNED NOT NULL,
  stringValue           VARCHAR(32) NULL,
  numberValue           FLOAT(10,5) NULL,
  dateValue             DATE NULL,
  booleanValue          TINYINT(1) UNSIGNED NULL,
  PRIMARY KEY( attrValueID )
);

