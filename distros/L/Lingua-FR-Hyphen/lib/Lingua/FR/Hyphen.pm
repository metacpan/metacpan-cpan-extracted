package Lingua::FR::Hyphen;

use 5.006;
use warnings;
use strict;
use Carp;

#===================================================================
# $Author     : Djibril Ousmanou  and Laurent Rosenfeld            $
# $Copyright  : 2015                                               $
# $Update     : 26/08/2015                                         $
# $AIM        : Hyphenate words for French language                $
#===================================================================
use utf8;

use vars qw / $VERSION /;
$VERSION = '1.01';

sub new {
	my ( $self, $ref_arguments ) = @_;

	my $this = {};
	bless $this, $self;

	# Check arguments
	$this->_check_arguments($ref_arguments);

	# Default French configuration
	$this->{_min_word}         = $ref_arguments->{min_word}         || 6;
	$this->{_min_prefix}       = $ref_arguments->{min_prefix}       || 3;
	$this->{_min_suffix}       = $ref_arguments->{min_suffix}       || 3;
	$this->{_cut_proper_nouns} = $ref_arguments->{cut_proper_nouns} || 0;
	$this->{_cut_compounds}    = $ref_arguments->{cut_compounds}    || 0;

	# Check arguments
	$this->_check_arguments($ref_arguments, 1);

	# hyphen tree initialisation
	$this->{_tree} = {};

	# Load all patterns (official patterns, exceptions, proper nouns…)
	$this->_load_fr_patterns;

	return $this;
}

sub _check_arguments {
	my ( $this, $ref_arguments, $check_complet ) = @_;

	# Check arguments
	if ( defined $ref_arguments and ref($ref_arguments) ne 'HASH' ) {
		croak "You have to use a hash reference as argument\n";
	}

	# Check arguments again
	if ( defined $ref_arguments and defined $check_complet ) {

		foreach my $option ( keys %{$ref_arguments} ) {
			if (! $this->{"_$option"} ) {
				croak "$option option not exists in " . __PACKAGE__ ."\n"
				. "Read documentation : perldoc " . __PACKAGE__ ."\n";
			}
		}
	}

	return 1;
}

sub _add_pattern {
	my ( $this, $pattern ) = @_;

	# Convert the pattern in string and points list
	# Pattern a1bc3d4 => [a, b, c, d] and [ 0, 1, 0, 3, 4 ]
	my @chars = grep { /\D/ } split //, $pattern;
	my @points = map { $_ || 0 } split /\D/, $pattern, -1;

	# Insert the pattern into the tree. Each character finds a child node
	# another level down in the tree, and leaf nodes have the list of
	# points. (This kind of tree is usually called a trie (the word comes from
	# retrieval) or a prefix tree.) It has high performance for things such
	# as words lookup in a dictionary.
	my $ref_tree = $this->{_tree};    # Copy ref tree
	foreach (@chars) {

		# Create new ref tree or modify it
		if ( !$ref_tree->{$_} ) { $ref_tree->{$_} = {}; }
		$ref_tree = $ref_tree->{$_};
	}
	$ref_tree->{_} = \@points;

	return 1;
}

sub _load_fr_patterns {
	my $this = shift;

	# Add official fr pattern
	$this->_add_pattern($_) foreach @{ $this->_get_official_fr_patterns() };

	# Add non official fr pattern
	$this->_add_pattern($_) foreach @{ $this->_get_non_official_fr_patterns() };

	# Load exceptions words
	foreach my $word_exception ( @{ $this->_get_exceptions_words } ) {
		( my $word = $word_exception ) =~ tr/-//d;

		# wo-rd-le => { wordle => [0, 0, 1, 0, 1, 0, 0] }
		# ||a||a||
		#__ a _ a __
		# -1 == do not omit trailing undefs
		$this->{_exceptions}->{$word} = [ 0, map { $_ eq '-' ? 1 : 0 } split /[^-]/, $word_exception, -1 ];
	}

	# Proper nouns
	$this->{_ref_proper_nouns} = $this->_get_exceptions_proper_nouns_words();
}

sub hyphenate {
	my ( $this, $word, $delim ) = @_;
	$delim ||= '-';

	# Short words aren't hyphenated.
	return $word if ( length($word) < $this->{_min_word} );

	# If all the characters of the word are upper case Unicode letters,
	# we don't hyphenate ACRONYMS
	return $word if ( $word =~ /^\p{Uppercase}+$/ );

	# Don't hyphenate proper nouns unless this is asked for.
	if ( $this->{_cut_proper_nouns} eq 0 ) {
		return $word if ( $this->{_ref_proper_nouns}->{ lc($word) } );
	}

	# Don't hyphenate compounds unless this is asked for.
	if ( $this->{_cut_compounds} eq 0 ) {
		return $word if ( $word =~ /-/ );
	}

	my @word = split //, $word;

	# If the word is an exception, get the stored points.
	my $ref_points = $this->{_exceptions}->{ lc($word) };

	# Word with spaces
	my $regex = '[\s+,\.;!\?]+';
	if ( $word =~ m{\s} ) {
		my @spaces = $word =~ m{($regex)}g;
		my @words  = split /$regex/, $word;
		my $result = '';
		for my $i ( 0 .. $#words ) {
			$result .= $this->hyphenate( $words[$i] );
			$result .= $spaces[$i] if ( $spaces[$i] );
		}
		return $result;
	}

	# no exception
	unless ($ref_points) {

		# List of characters with extremetis (.)
		my @work = ( '.', map { lc } @word, '.' );
		$ref_points = [ (0) x ( @work + 1 ) ];

		# For each character
		for my $index_charactere ( 0 .. $#work ) {
			my $ref_tree = $this->{_tree};

			for my $charactere ( @work[ $index_charactere .. $#work ] ) {
				last if ( !$ref_tree->{$charactere} );
				$ref_tree = $ref_tree->{$charactere};

				# There is a position in tree
				if ( my $ref_position = $ref_tree->{_} ) {
					for my $index_position_tree ( 0 .. $#$ref_position ) {

				# $ref_points->[$index_charactere + $index_position_tree]
				# = max($ref_points->[$index_charactere + $index_position_tree], $ref_position->[$index_position_tree]);
						if ( $ref_points->[ $index_charactere + $index_position_tree ] <
							$ref_position->[$index_position_tree] )
						{
							$ref_points->[ $index_charactere + $index_position_tree ] =
							  $ref_position->[$index_position_tree];
						}
					}
				}
			}
		}

		# No hyphens within the minimal length suffixes and prefixes
		$ref_points->[$_] = 0 for 0 .. $this->{_min_prefix};
		$ref_points->[$_] = 0 for -$this->{_min_suffix} - 1 .. -2;
	}

	# Examine the points to build the pieces list.
	my @pieces = ('');

	for my $i ( 0 .. length($word) - 1 ) {
		$pieces[-1] .= $word[$i];
		$ref_points->[ 2 + $i ] % 2 and push @pieces, '';
	}

	return join( $delim, @pieces );
}

sub _get_exceptions_words {
	return [qw /mai-son/];
}

sub _get_non_official_fr_patterns {
	return [qw//];
}

sub _get_exceptions_proper_nouns_words {
	my $this = shift;
	return {} if ( $this->{_cut_proper_nouns} != 0 );
	my %proper_nouns = map { lc($_) => 1 } qw /
	  Aaliyah Aarhus Aaron Aarschot Abbeville Abbie Abby Abd Abdallah Abdel Abdelkader
	  Abdias Abdoulaye Abebe Abel Abidjan Abigail Abitibi-Témiscamingue Abkhazie Abraham
	  ABS Abu Abuja Abymes Abyssinie Abélard Acadie Acapulco Accra Achard Achaïe Achgabat
	  Achéron Aconcagua Adalbert Adam Adamo Adamov Adams Adana Addis-Abeba Addison Adelbert
	  Adenauer Adige Adina ADN ADNc Adolfo Adolphe Adonaï Adonis Adour ADP Adrian Adriana
	  Adrien Adrienne ADSL Adèle Adélaïde Adélie Afghanistan Afrique Agamemnon Agatha Agathe
	  Agboville Agde Agen Aggée Aglaé Agnieszka Agnès Agrippine Ahmed Ahmedabad Aida Aidan
	  AIEA Aigoual Aimé Aimée Ain Airbus Aires Aisne Aix Aix-en-Provence Aix-la-Chapelle
	  Ajaccio Ajar AK-47 Akhenaton Akira Al-Qaïda Alabama Alain Alamo Alan Alaric Alaska
	  Alban Albane Albanie Albert Alberta Alberte Albertine Alberto Albertville Albi Albin
	  Albret Albuquerque Albéric Alceste Alcibiade Alcide Aldo Aldric Aldrin Alec Alegre
	  Alejandro Alek Aleksander Aleksandra Aleksei Alençon Alep Alessandra Alessandro Alex
	  Alexander Alexandra Alexandre Alexandrie Alexandrina Alexane Alexei Alexia Alexian
	  Alexis Alfonso Alfortville Alfred Algarve Alger Algérie Ali Alia Alice Alicia Alida
	  Alison Alistair Alix Aliénor Alken Allah Allais Allan Allemagne Allende Alleur Allier
	  Allwright Ally Allyson Alma Almaty Alonzo Alost Alpes Alpes-de-Haute-Provence Alpes-Maritimes
	  Alphonse Alpilles Alsace Alstom Altaï Althusser Alyssa Alzheimer Alès Alésia Amadeus
	  Amalthée Amand Amanda Amandine Amando Amar Amaury Amazone Amazonie Amber Amblève
	  Ambroise AMD Amel Amerigo Amiens Amina Amir Amira Amman Amos Amour Amphitrite Ampère
	  Amundsen Amy Amédée Amélia Amélie Aménophis Amérique Anacréon Anastase Anastasia
	  Anatole Anatoli Anatolie Anaxagore Anaximandre Anaximène Anaëlle Anaïs Anchorage
	  Andalousie Andaman Andenne Anderlecht Andersen Andes Andorre Andrea Andreas Andrew
	  Andrzej André Andréa Andrée Andy Angela Angeles Angelina Angelino Angelo Angers Angie
	  Anglet Angleterre Angola Angoulême Angoumois Anguilla Angus Angèle Angélique Anicet
	  Anissa Anita Anjou Ankara Ann Anna Annabelle Annabeth Anne Anne-Laure Anne-Marie
	  Annecy Annemasse Annette Annick Annie Anosov Anouilh Anouk Anquetil Ans Anschluss
	  Antalya Antananarivo Antarctique Anthelme Anthony Antibes Antigone Antigua-et-Barbuda
	  Antioche Antoine Antoinette Anton Antonia Antonietta Antonin Antonina Antonio Antony
	  Anubis Anvers Anémone Aoste Apennin Apennins Aphrodite Apollinaire Apolline Apollon
	  Apophis Appalaches Appenzell Apple April Apulée Aquitaine Arabie Arafat Aragon Aral
	  Ararat Arbois Arcachon Arcadie Arcady Archibald Archimède Arcimboldo Arctique Ardenne
	  Argenteuil Argentine Argonne Argos Argovie Ariane Ariel Arielle Arion Aristarque
	  Aristophane Aristote Arizona Ariège Arkansas Arkhangelsk Arlene Arles Arlette Arlington
	  Arlène Armageddon Armagnac Armand Armande Armel Armelle Armentières Armin Armor Armorique
	  ARN Arnaud ARNm Arno Arnold Arras Arsinoé Arsène Arthur Artois Artémis Artémision
	  Arès ASBL ASC ASCII Ascq Asgard Ashley Asie Asimov Asmara Asnières Asnières-sur-Seine
	  Asse Assouan Assourbanipal Assyrie Astana Astrakhan Astrid Asturies Asunción Atahualpa
	  Atatürk Ath Athabasca Athalie Athanase Athis-Mons Athènes Athéna Atlanta Atlantide
	  Atomium Atropos Attila Aubagne Aube Aubert Aubervilliers Aubin Aubrac Aubusson Auch
	  AUD Aude Audenarde Auderghem Audi Audiard Audin Audran Audrey Auger Augsbourg Augusta
	  Augustin Augustine Aulnay-sous-Bois Aunis Aure Aurelio Auriane Aurillac Auriol Aurore
	  Aurélia Aurélie Aurélien Auschwitz Austen Austerlitz Austin Australasie Australie
	  Australie-Occidentale Austrasie Autant-Lara Auteuil Autriche Autriche-Hongrie Auvergne
	  Ava Avalon Ave Aventin Aveyron Avicenne Avignon Avogadro AXA Axel Axelle Aya Aymar
	  Aymé Ayoub Azerbaïdjan Aziz Aziza Azov Açores Aïcha Aïd-el-Adha Aïd-el-Kébir Aïssa
	  Baar Babel Babylone Babylonie Bacchus Bach Bachelard Backlund Bacri Bade-Wurtemberg
	  Bagdad Bagneux Bagnolet Bahamas Bahamontes Bahreïn Baie-Comeau Baie-James Baire Bajazet
	  Bakounine Baldwin Balen Bali Balkans Ballesteros Baloutchistan Baltard Balthazar
	  Baltique Balutin Balzac Baléares Bamako Bambuck Banach Bandama Bandundu Bandung Banfora
	  Bangkok Bangladesh Bangui Banjul Banneux Baphomet Baptiste Bar-le-Duc Barbade Barbara
	  Barbusse Barcelone Bargmann Bari Barjavel Barlow Barnabé Barnard Barrière Barrot
	  Bart Bartali Barthélemy Barthélémy Bartolomé Bartók Baruch Barzotti Bas-Congo Bas-Rhin
	  Bas-Sassandra Bascharage BASF Basic Basile Basse-Côte-Nord Basse-Normandie Basse-Pointe
	  Basse-Terre Bassens Bassora Bastia Bastiat Bastien Bastogne Bata Bathurst Baudelaire
	  Baudouin Bauges Baumé Bavière Bayer Bayle Bayonne Bayreuth Baïkal Baïkonour Beach
	  Beauce Beaufort Beauharnais Beaujolais Beaumarchais Beaune Beauraing Beauvais Beauvoir
	  Beckett Becky Becquerel Beersel Beethoven BEF Beijing Belfast Belfort Belgique Belgrade
	  Belize Bell Belleville Bellérophon Beltrami Belzébuth Belém Ben Bendixson Benedetta
	  Benedict Benelux Bengale Benghazi Benita Benito Benjamin Benoît Benoîte Bentham Berchem-Sainte-Agathe
	  Berg Bergen Bergerac Bergson Bering Beringen Berkeley Berlin Berlioz Bermudes Bernadette
	  Bernard Bernardin Berne Bernhard Bernier Bernoulli Bernstein Berry Bers Berthe Berthelot
	  Bertille Bertrand Bertrange Besançon Bescherelle Besov Bessel Besson Beth Bethany
	  Betsy Bettembourg Betti Bettina Betty Beurling Beveren Beverly Beyrouth Bezons Bhagavad-Gîtâ
	  Bianca Bianchi Biarritz Bibie Bichkek Bieberbach Bielefeld Bienne Bienvenüe Bihar
	  Bilal Bilbao Bill Billetdoux Billy Bilzen Binche BIOS Birkenau Birkhoff Birmanie
	  Bishop Bismarck Bissau Bithynie Bizet Biélorussie Bjarn Björn Blachas Blagnac Blainville
	  Blake Blanc-Mesnil Blanche Blanco Blandine Blankenberge Blaschke Blier Bloemfontein
	  Blondin Blu-ray Bluetooth Blum Blücher BMW BMX Bob Bobbie Bobby Bobet Bobigny Bobo-Dioulasso
	  Boccace Boccherini Bochner Bochum Bodart Bode Boeing Bofill Bogotá Bohr Bohringer
	  Boileau Bois-Colombes Boisbriand Bolivar Bolivie Bollywood Bologne Boltzmann Bolyai
	  Bolívar Bombay Bonaparte Bondy Boniface Bonn Bonnard Bonne-Espérance Bonnie Boole
	  Borel Borg Borgia Borinage Boris Bornem Bornes Bornéo Bosch Bosco Bose Bosnie Bosnie-Herzégovine
	  Bossuet Boston Botrange Botswana Botticelli Bouaké Boucherot Boucherville Bouches-du-Rhône
	  Bougainville Bouglione Bouin Boulogne Boulogne-Billancourt Boulogne-sur-Mer Bourbaki
	  Bourbonnais Bourdieu Bourg-en-Bresse Bourges Bourgogne Bourgoin-Jallieu Bourvil Bouscat
	  Bouygues Bozzuffi Boèce Brabant Brad Bradford Bradley Brahim Brahma Brahmapoutre
	  Brahé Braille Braine-l'Alleud Braine-le-Comte Brandon Brant Braque Brasov Brassac
	  Brasília Bratislava Brauer Bray Brazzaville Brecht Brejnev Brenda Bresse Brest Bretagne
	  Brian Brianna Brice Bridge Bridgestone Brie Brigitte Brisbane Brittany Britten Brive-la-Gaillarde
	  Broca Broglie Bron Brongniart Brontë Brooke Brooklyn Brossard Brossolette Brown Broïda
	  Bruce Bruckner Bruegel Bruel Bruges Brunei Bruno Brunoy Brunswick Brutus Bruxelles
	  Bryan Brésil Brétigny-sur-Orge Brême Brûlé Brückner BTS Bubka Bucarest Budapest Buenos
	  Buffon Bujumbura Bukavu Bulgarie Bulle Bundesrat Bundestag Buridan Burkina Burnside
	  Burundi Bush Bussy-Saint-Georges Buxtehude Byrd Byron Byzance Bâle Bâle-Campagne
	  Bègles Béarn Béatrice Béatrix Bélinda Bénarès Bénin Bénédict Bénédicte Bérenger Bérengère
	  Bérénice Bérézina Bételgeuse Béthune Bétique Bézier Béziers Bézout Cabot CAC Cachan
	  CAD Cadillac Cadix Caelius Caen Cagliari Cagnes-sur-Mer Cahors Caire Caitlin Calabre
	  Calcutta Calderón Caleb Calestienne Calgary Cali Californie Caligula Calkin Callas
	  Callimaque Callisto Callot Caluire-et-Cuire Calvados Calvin Calédonie Camargue Cambacérès
	  Cambrai Cambridge Cambrésis Cameron Cameroun Camilla Camille Campanie Campbell Campine
	  Canada Canaletto Canaries Canaveral Canberra Candace Candice Cannes Cannet Cantabrie
	  Canton Cantons-de-l'Est Cantor Canyon CAP Cap Cap-Vert Capdevielle Capet Capitale-Nationale
	  Cappadoce Capucine Caracas Caradec Caravage Carcassonne Cardiff Caribert Caribou
	  Caristan Carl Carla Carlo Carloman Carlos Carlotta Carmella Carmen Carnot Carol Carole
	  Caron Carpates Carpeaux Carpentras Carrie Carroll Carstensz Cartan Carthage Carthagène
	  Cary Casablanca Casamance Casanova Casey Casimir Casimir-Perier Caspienne Cassandra
	  Cassavetes Cassidy Cassini Cassiopée Castille Castille-et-León Castres Catalina Catane
	  Cathy Caton Catulle Cau Caucase Cauchy Causses Cavaillon Cavelier Cavendish Cayenne
	  Caïn Caïphe CCP CD-ROM CDD CDI Cecil Cecily CEE Celle-Saint-Cloud Celsius Cendrars
	  Centrafrique Centre Centre-du-Québec Cerbère Cergy CERN Cervantès Cervi Cesàro Ceylan
	  Chablais Chad Chagall Chaillot Chalgrin Chalon-sur-Saône Chalons Chambly Chambord
	  Chamisso Chamonix Champagne Champagne-Ardenne Champigny-sur-Marne Champlain Champollion
	  Champs-Élysées Chancel Chanel Changchun Chantal Chappe Charcot Chardin Charente Charente-Maritime
	  Charlaine Charlebois Charlemagne Charlene Charleroi Charles Charles-Roux Charleville
	  Charlevoix Charlie Charline Charlotte Charlottetown Charly Charlène Charmaine Charolais
	  Charonne Chartres Charybde Chase Chasles Chatel Chatou Chaudfontaine Chaudière-Appalaches
	  Chaux-de-Fonds Chavanne Chaïm Chelles Chelon Chelsea Chemnitz Chengdu Chennai Cher
	  Cherubini Chesapeake Chesnay Chessex Cheval Chevalley Chevreul Chevrolet Cheyenne
	  CHF Chiara Chicago Childebert Childéric Chili Chilpéric Chimay Chimène Chine Chirac
	  Chisinau Chittagong Chloé Choisy-le-Roi Cholesky Cholet Chomsky Chongqing Chopin
	  Chris Christa Christel Christelle Christian Christiane Christiani Christie Christina
	  Christoffel Christoph Christophe Christopher Christèle Chrysaor Chrysler Chuck Churchill
	  Châlons-en-Champagne Châteauguay Châteauroux Châtelet Châtellerault Châtenay-Malabry
	  Chédid Chénier CIA Cicéron Cid Cie Cilicie Cincinnati Cindy Ciney Ciotat Circassie
	  Cisjordanie Citroën City Claire Clamart Clara Clarence Clarissa Clarisse Clark Claude
	  Claude-Nicolas Claudel Claudette Claudia Claudie Claudine Clavel Clavier Clemenceau
	  Clervaux Cleveland Clichy Clichy-sous-Bois Cliff Clifford Clifton Clinton Clio Clotaire
	  Clotilde Clovis Cloé Cluny Clyde Cléa Clélia Clémence Clément Clémentine Cléopâtre
	  CMU CNES CNRS CNY Cocchiante Cochinchine Cocteau COD Cognac Cohen COI Coire Colbert
	  Colette Colin Coline Colisée Colleen Colmar Cologne Colomb Colombes Colombie Colombie-Britannique
	  Colomiers Colorado Columbus Combs-la-Ville Commonwealth Comores Comoé Compiègne Compostelle
	  Conakry Conan Concarneau Concetta Condorcet Condroz Conflans-Sainte-Honorine Confortès
	  Congo Connecticut Connie Connor Connors Conquérant Conrad Constable Constance Constant
	  Constantine Constantinople Cook Copenhague Copernic Coppi Coralie Coraline Corbeil-Essonnes
	  Corbusier Cordelia Cordoue Corentin Corentine Corey Corfou Corine Corinne Corinthe
	  Cormeilles-en-Parisis Corneau Corneille Cornouailles Corogne Corrèze Corse Corse-du-Sud
	  Cortés Corée Cosette Cosima Costa Costner Cotentin Cotonou Cottençon Cotton Coty
	  Coudekerque-Branche Couesnon Coulomb Courbet Courbevoie Courcelles Courneuve Courteline
	  Courtrai Cousteau Coutin Coué Coxyde Cracovie Craig Cranach Creil Creuse Creusot
	  Crimée Critias Cro-Magnon Croatie Crofton Crohn Croix Cromwell CRS Crusoé Crète Crésus
	  Cuba Cuneo Cupidon Curaçao Curie Cushing Cuvier Cuzco Cybèle Cyclades Cynthia Cyprien
	  Cyrielle Cyril Cyrille Cyrus Cyrène Cyrénaïque Czestochowa Cécile Cécilia Cédric
	  Célestine Célia Célimène Céline Cérès César Césarée Cévennes Cézanne Cîteaux Côme
	  Côte-Nord Côte-Saint-Luc Côtes-du-Nord d'Annunzio D'Holbach d'Urville DAB Dacca Dacie
	  Dagobert Daguerre Dahl Dahlander Dahomey Daimler Daisy Dakar Dakota Dale Dali Dallas
	  Daloa Dalton Dalí Damas Damase Damien Dammarie-les-Lys Damoclès Dan Dana Danaé Danel
	  Daniel Daniela Daniella Danielle Danilevsky Daninos Danièle Danny Danone Dante Danton
	  Danube Dany Daoud Darboux Dardanelles Darfour Dario Darius Darjeeling Darren Darryl
	  Daryl Dassault Daudet Daumier Dauphiné Dave David David-Neel Davis Davos Davy Dawn
	  Dean Deauville Debbie Debra Debrecen Debussy Decoin Dedekind Defoe Degas Dehn Deinze
	  Delacroix Delaunay Delaware Delhi Delibes Dell Delphes Delphine Delvaux Denain Deneuve
	  Denise Denjoy Dennis Denver Depardieu Deraime Derain Deray Derek Derrida Desargues
	  Deschanel Desdémone Desmarets Desmond Desmoulins Desnos Despina DESS Detroit Deucalion
	  Deuil-la-Barre Deutéronome Deux-Siciles Deux-Sèvres Dhabi DHEA Dhotel Dhuis Diana
	  Diarmuid Dick Dickens Diderot Didier Diego Diekirch Dieppe Diest Dietikon Dieu Dieudonné
	  Digne-les-Bains Dijon Dilbeek Dimitri Dina Dinant Dioclétien Diodore Diogène Diois
	  Dioné Diophante Dior Dirac Dirichlet Disney Ditanyè Djamel Djamila Djeddah Djerba
	  Djibril Djoser Dmitri Dniepr Dnipropetrovsk Docteure Dodoma Doha Dole Dollard-des-Ormeaux
	  DOM DOM-TOM Dombes Domenico Domingo Dominic Dominique Domitien Domitille Don Donald
	  Donetsk Dongen Dongguan Donizetti Donna Donnie Donovan Doppler Dordogne Doreen Dorgelès
	  Doriane Dorine Doris Dormael Dorothy Dorothée Dortmund Dostoïevski Douai Douala Doubs
	  Doug Douglas Doumer Doumergue Douvres Doyle Dracula Draguignan Drake Drancy Draveil
	  Dresde Dreux Drew Dreyfus DRH Drummondville Druon Drut Drôme Dubaï Dublin Dubois
	  Dubuffet Dubuisson Duchamp Duchenne Dudelange Dufay Dufy Duhamel Duisburg Dukas Dulac
	  Dumont Dunant Duncan Dunedin Dunford Dunkerque Dunlop Duplessis Dupont Duquenne Durance
	  Durban Durbuy Durkheim DVD DVD-ROM Dvorák Dwayne Dwight Dyck Dylan Dynkin Dysnomie
	  Décines-Charpieu Déimos Déjanire Délos Démocrite Démosthène Déméter Déon Désiré Désirée
	  Dübendorf Düsseldorf Earl Easrman Eaubonne Ebit Ebola Echternach Eddie Eddy Edegem
	  Edgar Edgard Edgardo Edison Edmond Edmonde Edmonton Edmund Eduardo Edward Edwige
	  EEPROM Eeyou Egalité Ehrenpreis Ehresmann Eibit Eicher Eiffel Eileen Eilenberg Eilleen
	  Einstein Eio Eisenbud Eisenhower Eisenstein Ekaterina Ekaterinbourg Elaine Elbe Elbrouz
	  Elena Elie Elijah Eliott Elizabeth Ellen Elme Elohim Elsa Elvire Eléonore Emil Emile
	  Emilio Emily Emma Emmanuel Emmanuelle Emmaüs Emmen Emmett Emmy Empédocle Encelade
	  Enguerrand Enora Enrico Enrique Enzo EPROM Epstein Erevan Erfurt Eric Erica Erik
	  Erin Erié Ermont Ernest Ernestine Ernesto Ernie Erwan ESA Escaut Esch-sur-Alzette
	  Esclaves Escudéro Esculape Esdras Esméralda Esneux Espagne Espelette Esquilin Essen
	  Essonne Esteban Estelle Esther Estonie Estrie Estrémadure Estérel Etan Etchérelli
	  Ethernet Etienne Etna Ettelbruck Etterbeek Euclide Eudes Eugène Eugénie Eulalie Euler
	  Euphrate Euphrosyne EUR Eurasie Eure Eure-et-Loir Euripide Eurogroupe Europe Europol
	  Eurydice Eusèbe Euterpe Eva Evan Eve Evelyn Evere Everest Evergem Evrard Exbrayat
	  Extrême-Orient ExxonMobil Eyck Ezra Fabergé Fabian Fabien Fabienne Fabio Fabiola
	  Fabrizio Fadila Fagnes Fahrenheit FAI Fairbanks Faisalabad Faith Faldo Falkland Fallières
	  Famenne Fanny Fantin-Latour FAQ Faraday Farah Farid Farida Farnèse Farouk Faso Fatiha
	  Fatou Fatoumata Fauconnier Faulkner Faure Faust Faustine Fausto Fayette FBI Federer
	  FedEx Fehling Feldman Felicia Felicity Felipe Feller Ferdinand Fergus Fermat Fermi
	  Fernande Fernandel Fernandez Fernando Ferniot Ferrare Ferrari Ferraris Ferret Ferry
	  Feydeau Feynman Fiacre Fiat Fibonacci Fidji Fignon Filipa Finistère Finlande Finn
	  Fiona Firefox FireWire Firmin Fischer Fitzgerald Flamel Flammarion Flandre Flandre-Occidentale
	  Flaubert Flavie Flavien Flavio Fleur Fleurus Fleury-les-Aubrais Flora Flore Florence
	  Florentin Florentine Florian Floriane Floride Florine Floyd Flémalle FMI Foch Fock
	  Foix Fontaine Fontainebleau Fontenay Fontenay-aux-Roses Fontenay-sous-Bois Fontenelle
	  Ford Forest Forestier Forez Formose Fort-de-France Fortaleza Fortran Fosbury Fouad
	  Fouché Fougères Fourier Fouroux Fragonard Frameries Fran Franca France Francesca
	  Francfort Francfort-sur-le-Main Franche-Comté Francine Francis Francisco Franck Franco
	  Francorchamps Frank Frankenstein Frankie Franklin Frantz Franz François François-Xavier
	  Frauenfeld Fraïssé Fred Freddy Frederick Fredericton Fredholm Free Freetown Frenet
	  Fresnes Fresno Freud FRF Fribourg Friedman Friedmann Friedrich Frioul Fritz Frobenius
	  Frontignan Frounze Fréchet Frédéric Frédérique Fréhel Fréjus FTP Fubini Fuchs Fujita
	  Fukuoka Fukushima Fulcanelli Fuller Funès Futuna Fécamp Félicie Félicien Félicité
	  Fénelon Féroé Gabe Gabin Gabon Gaborone Gabriel Gabriele Gabriella Gabrielle Gaetano
	  Gail Gainsborough Gal Galaad Galabru Galathée Galatie Galatée Galen Galerkin Galice
	  Galileo Galilée Galles Gallien Gallimard Galois Gambetta Gambie Gand Gandhi Gange
	  Gantt Ganymède Gap Garcia Gard Garde Garenne-Colombes Gareth Gargantua Garges-lès-Gonesse
	  Garin Garnier Garonne Garrett Garros Gary Gascogne Gaspard Gaspésie Gaspésie–Îles-de-la-Madeleinee
	  Gaston Gate Gatien Gatineau Gaudi Gaudí Gauguin Gaule Gaulle Gaume Gauss Gauteng
	  Gautier Gauvain Gavin Gaza Gaziantep Gazprom Gaétan Gaël Gaëlle Gaëtan Gaëtane Gaïa
	  GBP Gdansk GDF Geel Geiger Gelsenkirchen Gembloux Gemma Gene Geneviève Genevoix Genk
	  Genève Geoff Geoffrey Geoffroy George Georges Georgetown Georgette Georgia Georgina
	  Geraldo Gerda Gergovie Gerhard Germain Germaine Germanie Geronimo Gers Gertrude Gestapo
	  Ghana Ghislain Ghislaine Giacometti Giacomo Giap Gibbs Gibit Gibraltar Gide Gif-sur-Yvette
	  Gilbert Gilberte Gildas Gileppe Gilgamesh Gilles Gillian Gina Ginette Ginger Gino
	  Giono Giorgio Giorgione Giotto Giovanna Giovanni Girard Giraudeau Gironde Giscard
	  Giulia Giuseppe Gizeh Gladys Glaris Glasgow Glen Glenn Gluck Glück GMT Goa Gobi Godefroid
	  Goethe Gogh Gogol Goitschel Golan Goldbach Golden Golgi Golgotha Goliath Gomorrhe
	  Gondwana Gonesse Gontran Gonzague Goodyear Google Gorbatchev Gordon Gorenstein Gorki
	  Goursat Goussainville Goya GPL GPS Graal Gracq Gradignan Graeme Graham Gram Gram-Schmidt
	  Grammont Granby Grand Grand-Quevilly Grand-Rivière Grande-Bretagne Grande-Synthe
	  Grant Grasse Grassmann Graz Graziella Greene Greenville Greenwich Greg Gregor Gregory
	  Grenelle Grenoble Gretchen Grevisse Grieg Griffith Grigny Grigory Grimbergen Grimm
	  Gris-Nez Grisons Groenland Gropius Gross Grothendieck Grâce-Hollogne Grèce Gréco
	  Grégory Grévy Grönwall Grötzsch GSM Gstaad Gtep Guadalajara Guadeloupe Guam Guantánamo
	  Guayaquil Guenièvre Guernesey Guglielmo Guichard Guilhem Guillaume Guillermo Guinée
	  Guiseppe Gujarat Gus Gustav Gustave Gustavo Gutenberg Guy Guyana Guyancourt Guyane
	  Guylaine Guénolé Guénon Guéret Guétary Gwen Gwenaël Gwenaëlle Gwendal Gwendoline
	  Gwenola Gwladys Gwyneth Gwénaël Gâtinais Gédéon Géorgie Gérald Géraldine Gérard Géraud
	  Gérôme Gévaudan Gênes Gödel Göring Göteborg Günther Haar Habacuc Habib Habsbourg
	  Hadrien Hadès Haendel Hague Haguenau Hahn Hainaut Hakim Hal Haley Halicarnasse Halifax
	  Hall Halle Halley Halloween Hamas Hambourg Hamel Hamid Hamilton Hamme Hammourabi
	  Hamza Han Hank Hankel Hannah Hannibal Hanoucca Hanovre Hanoï Hans Hansen Harare Harbin
	  Hardouin-Mansart Hardy Harelbeke Harlem Harmony Harnack Harold Harrison Harry Hartogs
	  Harunobu Harvard Harvey Hassan Hasselt Haumea Hausdorff Haussmann Haut-Rhin Haut-Sassandra
	  Haute-Garonne Haute-Loire Haute-Marne Haute-Normandie Haute-Savoie Haute-Saône Haute-Vienne
	  Hautes-Pyrénées Hauts-de-Seine Havane Havre Hawaï Hawking Haydn Haydée Haye Hayek
	  Hazebrouck Hazel Haïfa Haïti HDMI Heather Heaviside Hecke Hector Hegel Heidegger
	  Heimlich Heinrich Heisenberg Heist-op-den-Berg Helen Helsinki Helvétie Hemingway
	  Henriette Henrik Henrique Henry Herbert Herblay Herculanum Hercule Herentals Herman
	  Hermine Hermione Hermite Hermès Hernan Herschel Herstal Hertz Herve Hervé Hesbaye
	  Hesse Hessenberg Hestia Heusden-Zolder Hicham Higelin Higgs Highlands Hilbert Hilda
	  Hildegarde Hillary Himalaya Hinault Hindenburg Hipparque Hippocrate Hippolyte Hiro
	  Hiroshima Hispanie Hitachi Hitchcock Hitler Hitomi HIV HLM Hobart Hobbes Hochschild
	  Hoeilaart Hoffmann Hokkaido Hokusai Hollande Holly Hollywood Holmes Homère Honda
	  Honegger Hong Hongrie Honolulu Honorine Honoré Honshu Hopf Hopkinson Hopper Horace
	  Horn Horner Hortense Horton Horus Houilles Householder Houston Houthalen-Helchteren
	  HTML Hubble Hubert Hubert-Félix Hudson Hugo Hugues Huguette Humbolt Hume Hun Huntington
	  Huron Hurwitz Husserl Huy Huygens Hyacinthe Hyades Hyderabad Hypatie Hypérion Hyundai
	  Hébrides Hécate Hélicon Héliogabale Héliopolis Hélios Héloïse Hélène Héléna Hénin-Beaumont
	  Héphaïstos Héra Héraclite Héraclès Hérault Hérode Hérodote Hérouville-Saint-Clair
	  Hô-Chi-Minh-Ville Hölder Iain Ian Ibadan IBAN Ibiza IBM Ibrahim Ibrahima Ibsen Icare
	  Idaho Idris Idriss Iekaterinbourg Ienissei Ienisseï Ier Ignace Igor Iguaçu IIde IIe
	  IIIe IIIᵉ IInd Ilan Ilana Iliad Iliade Ilias Ille-et-Vilaine Illinois Illkirch-Graffenstaden
	  Ilyas Inaya Inde Indiana Indianapolis Indochine Indonésie Indre Indre-et-Loire Indurain
	  Ingemar Ingolstadt Ingres Ingrid Inna Innsbruck INSEE Insulinde Intel Interallié
	  Interpol Inès Ionesco Iowa Iphigénie Iqaluit Irak Iran Ire Irina Irlande IRM Iroise
	  Irénée Isa Isaac Isabeau Isabel Isabella Isabelle Isadora Isaiah Isaïe ISBN Iseult
	  Isidore Ising Isis Iskander Islamabad Island Islande Ismaël Ismérie ISO Isobel Ispahan
	  Issy-les-Moulineaux Istanbul Istchee Istres Istrie Isère Italie Itô IUFM IUT Iva
	  Ivana Ivanhoé Ivar IVe IVᵉ IVG Ivry-sur-Seine Iwasawa IXe Ixelles Ixion Izegem
	  J.-C Jack Jackie Jackson Jacksonville Jacky Jaco Jacob Jacobi Jacobson
	  Jacques Jade Jaffa Jaguar Jaime Jakarta Jake Jamahiriya Jamal Jamaïque Jamblique
	  Jamie Jamil Jamila Jamésie Jan Jana Jane Janeiro Janet Janette Janice Janine Jankélévitch
	  Japet Japon Jared Jasmine Jason Jaurès Java JavaScript Javier Jawad Jay Jayne Jazy
	  Jean-Baptiste Jean-Bernard Jean-Charles Jean-Christophe Jean-Claude Jean-François
	  Jean-Louis Jean-Loup Jean-Luc Jean-Marc Jean-Marie Jean-Michel Jean-Noël Jean-Pascal
	  Jean-Paul Jean-Philippe Jean-Pierre Jean-Sébastien Jean-Yves Jeanine Jeanne Jeannette
	  Jeannot Jeff Jefferson Jeffrey Jelena Jemappes Jemima Jenna Jennifer Jenny Jensen
	  Jeremy Jerry Jersey Jess Jesse Jessica Jessie Jessy Jewel Jill Jillian Jim Jimmy
	  Joan Joanie Joanna Joannie Joaquim Jocelyn Jocelyne Joconde Jocrisse Jodie Jody Joe
	  Joffre Joffrey Johan Johann Johanna Johannes Johannesburg John Johnny Johnson Jon
	  Jonathan Jones Jordan Jordanie Jorge Jorgen Joris Joseph Josepha Josephson Josette
	  Joshua Josiane Josie Josué Josèphe José Josée Joséphine Joule Jourdain Joué-lès-Tours
	  Joël Joëlle JPY Juan Juana Juanita Juda Judas Judd Jude Judicaël Judith Judy Judée
	  Jugnot Jules Julia Julian Juliana Julianna Julianne Julie Julien Julienne Juliette
	  Julius June Jung Junon Jupiter Jura Jurieu Juste Justin Justine Justinien Juvénal
	  Jéricho Jérusalem Jérémie Jérémy Jérôme Jésus Jésus-Christ Jürgen K-O Kaboul Kabylie
	  Kacey Kadiogo Kafka Kahan Kairouan Kaitlyn Kalahari Kaliningrad Kalman Kaluza Kamal
	  Kampala Kamtchatka Kananga Kandinsky Kandiski Kanpur Kansas Kant Kapellen Karachi
	  Kari Karim Karima Karina Karine Karl Karlsruhe Karnak Karnataka Karnaugh Karol Kasaï-Occidental
	  Kassovitz Katanga Kate Katherina Katherine Kathleen Kathryn Kathy Katia Katie Kativik
	  Katmandou Katowice Katsushita Katy Katznelson Kaunas Kawasaki Kay Kayl Kayla Kaylee
	  Kazan Keeling Kees Kehlen Keira Keith Keller Kelly Kelsey Kelvin Ken Kendra Kennedy
	  Kenneth Kenny Kent Kentucky Kenya Kenza Kenzo Kepler Kerguelen Kerr Kessel Kevin
	  KGB Khadija Khaled Khalid Khalil Kharkov Khartoum Kheira Khintchine Khrouchtchev
	  Khéphren Kibit Kidal Kiel Kiera Kierkegaard Kiev Kigali Kilian Kilimandjaro Killian
	  Killy Kim Kimberley Kimberly King Kingston Kingstown Kinshasa Kio Kipling Kippour
	  Kirchhoff Kirghizie Kirghizistan Kirghizstan Kiribati Kirk Kirsten Kisangani Kitchin
	  Kjeldahl Klammer Klaus Klee Klein Klimt Klitzing Klondike KMF Knokke-Heist Knossos
	  Koch Kodaira Koekelberg Kolkata Kolmogorov Kolwezi Kolyma Kondratiev Kong Konrad
	  Konya Korhogo Korteweg Kosovo Kourou Koursk Kouïbychev Kovalevskaïa Koweït Kosciuszko Kościuszko
	  Krefeld Krein Kremlin Kremlin-Bicêtre Kriens Krishna Krishnamurti Kristen Kristin
	  Kristof Kronecker Krull Kuala Kuiper Kuratowski Kurdistan Kurosh Kurt Kutta Kyle
	  Kylie Kyllian Kyoto Kyushu Köniz L'Haÿ-les-Roses L'Oréal Labrador Lac Lacan Lachésis
	  Lacroix Lada Laeken Lafarge Lafont Laforêt Lagny-sur-Marne Lagos Lagrange Laguerre
	  Lake Lalande Lalanne Laly Lamarck Lamartine Lambersart Lambert Lamborghini Lamotte
	  Lanaken Lanaudière Lancelot Lancia Lancy Landau Landen Landes Landry Lanester Langerhans
	  LanguageTool Languedoc Languedoc-Roussillon Lanka Lanoux Lanvaux Lanvin Laon Laos
	  Lapointe Laponie Lara Larissa Larousse Larry Lars Larsen Larzac Las Lascaux Lassay-les-Châteaux
	  Latium Latran Laura Laurasie Laure Laureen Laureline Lauren Laurence Laurent Laurentides
	  Lauriane Laurianne Laurie Laurine Lausanne Lautner Laval Lavil Lavilliers Lavoie
	  Lavoisier Lawrence Lazare Laërce LCD Lebesgue Lebrun Leclerc LED Ledoux Leducq Lee
	  Leeuw-Saint-Pierre Lefebvre Lefschetz Legendre Lehmer Leibnitz Leibniz Leicester
	  Leila Leipzig Lejeune Lela Leland Lemarque Lemaître Lemond Lena Leningrad Lenny Lenorman
	  Lenz Leone Leonora Leopoldt Leroy Lesley Leslie Lesotho Lesse Lessing Lester Lettonie
	  Levallois-Perret Levi Levi-Civita Levinson Lewis Lex Leyde Leyla Leïla LGV Lhassa
	  Liban Libby Liberia Libourne LibreOffice Libreville Libye Liechtenstein Lierre Ligurie
	  Lilas Lili Lilian Liliane Lilith Lille Lillehammer Lilongwe Lilou Lily Lima Limbourg
	  Limousin Lina Lincoln Linda Lindbergh Lindsay Lindsey Line Linford Linné Lino Linus
	  Lionel Liouville Lipschitz Lisa Lisbeth Lisbonne Lise Lisieux Lisle Lison Lisp Lissajous
	  Littlewood Littré Lituanie Liverpool Livia Livingstone Livourne Livry-Gargan Liz
	  Lizzie Liège Liénard Liévin Ljubljana Lloyd Loan Loane Lobatchevski Lochristi Locke
	  Logan Loir Loir-et-Cher Loire Loire-Atlantique Loiret Lojasiewicz Lokeren Lola Lombardie
	  Lomé London Londres Long Longjumeau Longueuil Lons-le-Saunier Loos Lorelei Lorena
	  Lorenz Lorenzo Loretta Lorette Lori Lorient Lormont Lorraine Los Lot Lot-et-Garonne
	  Lotharingie Lotus Lou Louane Loubet Loubna Louis Louis-Antoine Louis-Philippe Louisa
	  Louisette Louisiane Louison Louisville Louka Louksor Louna Louvain Louvière Louvre
	  Lovecraft Loyola Lozère Loïc Loïs Loïse LSD Luanda Lublin Lubumbashi Lubéron Luc
	  Lucas Lucchini Lucerne Lucette Lucia Luciano Lucie Lucien Lucienne Lucifer Lucile
	  Lucinda Lucrezia Lucrèce Lucullus Lucy Ludivine Ludovic Ludwig Lufthansa Lug Lugano
	  Luis Luka Lukas Luke Lulle Lully Lumière Lumpur Luna Lune Lunel Lunéville Lure Lusaka
	  Lusitanie Luther Lutèce Luxembourg LVMH Lyapunov Lycaonie Lycie Lydia Lydie Lyle
	  Lyne Lynn Lyon László Lætitia Léa Léandre Léane Léger Léman Léna Lénine Lény Léo
	  Léonard Léonce Léone Léonidas Léonide Léonie Léontine Léopold Léopoldville Lévi-Strauss
	  Lévitique Lévy Lódz Lübeck Maaseik Maasmechelen Maastricht Mabel Mac Mac-Mahon Macao
	  Mach Macha Machhad Machiavel Macias Mackenzie MacLane Maclaurin Macédoine Madagascar
	  Maddie Madeleine Madeline Mademoiselle Madras Madrid Maeterlinck Maeva Magali Magalie
	  Magdala Magdalena Magdebourg Magellan Maggie Maghreb Maginot Magnus Magog Magritte
	  Maguy Maharashtra Mahaut Mahler Mahmoud Mahomet Mahon Mahâbhârata Maillol Maimouna
	  Maine-et-Loire Maisons-Alfort Maisons-Laffitte Majorana Majorque Malabo Malachie
	  Malakoff Malawi Malcev Malcolm Maldegem Maldives Malebranche Mali Malik Malika Malines
	  Mallet-Joris Mallory Malmö Malouines Malraux Malte Malthus Mamadou Maman Mamer Managua
	  Manaus Manche Manchester Mandchourie Mandela Mandelbrot Mandy Manet Manfred Manhattan
	  Maniema Manille Manitoba Mannheim Manon Manosque Mans Mansart Manset Mantes-la-Jolie
	  Manuel Manuela Manuella Mao Maputo Mara Maracaibo Marat Marc Marc-Antoine Marc-Olivier
	  Marcel Marcela Marcelin Marceline Marcelle Marcellin Marcelline Marcello Marcelo
	  Marche-en-Famenne Marcia Marcion Marco Marconi Marcos Marcq-en-Barœul Marcus Marcy
	  Mardouk Margaret Margaux Margherita Margie Margot Marguerite Maria Marianne Mariannes
	  Marie-Agnès Marie-Ange Marie-Anne Marie-Antoinette Marie-Chantal Marie-Charlotte
	  Marie-Claire Marie-Claude Marie-Cécile Marie-Dominique Marie-France Marie-Françoise
	  Marie-Jeanne Marie-Josèphe Marie-José Marie-Laure Marie-Line Marie-Louise Marie-Madeleine
	  Marie-Odile Marie-Paule Marie-Pierre Marie-Rose Marie-Thérèse Marielle Mariette Marignan
	  Marilou Marilyn Marilyne Marina Marine Mario Marion Marisa Marisol Marissa Marita
	  Marivaux Marjorie Mark Markov Markus Marlène Marmara Marne Marnie Maroc Marot Marouane
	  Mars Marseille Marshall Marta Martenot Martha Marthe Martial Martigues Martin Martine
	  Martini Martinien Martinique Marty Marvin Marx Mary Maryam Maryland Maryline Marylise
	  Marylène Maryse Maryvonne Mascate Mascouche Maserati Mason Massachusetts Massari
	  Massy Masséna Mateo Mathias Mathieu Mathilda Mathilde Mathis Mathurin Mathusalem
	  Mathéo Matignon Matisse Matt Matteo Matthew Matthias Matthieu Mattéo Maubeuge Maud
	  Maugham Maupassant Maure Maureen Mauriac Maurice Mauricette Mauricie Mauricio Mauritanie
	  Max Maxence Maxime Maximilien Maximin Maxine Maxwell Mayence Mayenne Maylis Mayotte
	  Maéva Maël Maëlle Maëlys Maïwen Maïwenn Mbit Mbuji-Mayi McKinley Meaux Mecklembourg
	  Mecque Medan Medellín Meg Megan Megumi Mehdi Mehmet Meiji Meknès Melaine Melanie
	  Melchior Melinda Melissa Mellin Melun Melville Melvin Memphis Mende Mendel Mendeleïev
	  Menin Menton Mené Mercalli Mercantour Mercator Mercie Merckx Mercure Meredith Merelbeke
	  Merle Merleau-Ponty Merlin Meryl Mesdames Mesdemoiselles Messaline Messieurs Messine
	  Metz Meudon Meurthe Meurthe-et-Moselle Meuse Mexico Mexique Meyzieu Mezzogiorno Mgr
	  Miami Mibit Michael Michaël Michel Michel-Ange Michelet Michelin Micheline Michelle
	  Michigan Michèle Michée Mickaël Micronésie Microsoft Midas Midgard Midi-Pyrénées
	  Mikael Mikaël Mike Miklos Mila Milan Milankovitch Mildred Milgram Milhaud Mill Millau
	  Millerand Milne Milo Milton Milwaukee Mimas Mimoun Mina Minakshisundaram Mindy Minkowski
	  Minnesota Minos Minsk Mio Miou-Miou Miquelon Mir Mira Mirabeau Mirabel Miramas Miranda
	  Miró Mises Mississippi Missouri Mitch Mithra Mithridate Mitsubishi Mitterrand Mlle
	  Mnémosyne Moab Mocky Modiano Modigliani Mogadiscio Mohamed Mohammed Mohenjo-daro
	  Moira Moire Mol Moldavie Molenbeek-Saint-Jean Molise Molière Molly Moloch Molotov
	  Mona Monaco Mondercange Mondrian Monet Monge Mongolie Mongolie-Intérieure Monica
	  Monod Monrovia Mons Mons-en-Barœul Monsieur Mont-Blanc Mont-de-Marsan Mont-Saint-Aignan
	  Montaigne Montaigu-Zichem Montana Montand Montauban Montbéliard Montceau-les-Mines
	  Monte-Carlo Montel Monterrey Montesquieu Monteverdi Montevideo Montfermeil Montgeron
	  Monticelli Montigny-le-Bretonneux Montigny-lès-Metz Montluçon Montmartre Montmorency
	  Montpellier Montreuil Montreux Montrouge Montréal Montserrat Montélimar Monténégro
	  Moore Morad Morand Moravia Moravie Morbihan Mordell More Moreau Morel Morera Moresby
	  Morgane Morisot Morley Morphée Morse Mort Morteau Morton Mortsel Morvan Moréno Moscou
	  Moselle Moser Moser-Proell Mossad Mouhoun Moulin Moulins Mouloud Mounir Mourad Mourmansk
	  Moussa Moussorgski Moyen-Orient Mozambique Mozart Mozilla Moïse Mpc Mrs MST Mtep
	  Mulhouse Mumbai Munch Munich Murat Murcie Mureaux Muret Muriel Murielle Murphy Murray
	  Mussolini Mustapha Myanmar Mykérinos Mylène Myriam Mâcon Mâconnais Médard Médicis
	  Médée Médéric Mée-sur-Seine Mégane Mékong Mélanie Mélanésie Mélia Mélina Méline Mélisande
	  Mélissandre Méliès Méphistophélès Mérida Mérignac Mérimée Mésie Mésopotamie Mézières
	  Mönchengladbach Müller Münchhausen Münster N'Djamena Nabil Nabuchodonosor Nadia Nadine
	  Nadège Nagasaki Nagata Nagoya Nagy Nahum Naimark Nain Nairobi Nakayama Namibie Namur
	  Nankin Nanterre Nantes Naomi Naples Napoléon Narbonne Narcisse NASA Nash Nashville
	  Nassera Nassim Nassima Nastase Natacha Natal Natalia Natascha Natasha Nate Nathalie
	  Nathanaël Nathanaëlle Nathaniel Nauru Navarre Navier-Stokes Naypyidaw Nazareth Nazca
	  Neandertal Nebraska Nehru Neil Neila Nelly Nelson Neptune Neruda Nerval Nessus Nestlé
	  Neuchâtel Neuilly-sur-Marne Neuilly-sur-Seine Neumann Neustrie Nevada Nevanlinna
	  New Newcastle Newton Niagara Niamey Nicaragua Nice Nicholas Nick Nicklaus Nicky Nicodème
	  Nicole Nicoletta Nicolette Nicomaque Nicosie Nicée Nidwald Niels Niemeyer Nietzsche
	  Niger Nigeria Nijlen Nikita Nikki Nikodym Nikola Nikolaï Nil Nilda Nils Nina Ninive
	  Ninon Ninove Nintendo Niort Nissan Nivelles Nivernais Nizan Nièvre Niépce Noa Noah
	  Nobel Noether Nogent-sur-Marne Noire Noiret Noirmoutier Noisy-le-Grand Noisy-le-Sec
	  Nolan Nolwenn Nora Norbert Nord Nord-du-Québec Nord-Kivu Nord-Pas-de-Calais Nordine
	  Norique Norma Norman Normandie Norne Northumbrie Norton Norvège Notre-Dame Nottingham
	  Nouméa Nour Noura Noureddine Nourissier Nouveau-Brunswick Nouveau-Mexique Nouveau-Québec
	  Nouvelle-Galles Nouvelle-Guinée Nouvelle-Orléans Nouvelle-Zélande Nouvelle-Écosse
	  Novgorod Novossibirsk Noé Noémie Noël Noëlle NSA Nubie Numidie Nunavik Nunavut Nuremberg
	  Nyquist Nyx Néfertiti Néguev Néhémie Némésis Népal Néron Néréide Nîmes Oakland Obama
	  Obwald Obéron Ocana Occam Occitanie OCDE Ockham Octave Océane Océanie Odessa Odette
	  Odile Odilon Odin Odon Odéon Offenbach Ogier OGM Ohio Ohm Oisans Oise Oklahoma Olaf
	  Olga Oliver Olivet Olivia Olivier Olympe Olympia Olympie Oléron Omaha Oman Omar Ombrie
	  Omdourman OMS Omsk ONG Ontario ONU Oort Oostkamp OPA OPE Opel OpenOffice OPEP Ophélie
	  OPR OPV Oran Orange Orcades Oregon Oren Oriane Origène Orion ORL Orlando Orlane Orly
	  Orne Ornella Oronte Orphée Orsay Orvault Orwell Orénoque Osaka Oscar Osiris Oslo
	  Ostende Ostie Ostrava Oswald OTAN Othe Othello Othon Ottawa Ottignies-Louvain-la-Neuve
	  Ouessant Ouganda Ougarit Oulan-Bator Oullins Oupeye Oural Ouranos Ouroboros Ours
	  Oury Oussama Outaouais Ouzbékistan Overijse Ovide Oviedo Owen Oxford Oyonnax Ozoir-la-Ferrière
	  Pablo Paco Pacôme Padoue Padé Paganini Pagnol Paige Painlevé Pakistan Palaiseau Palaos
	  Palerme Palestine Paley Pallas Paloma Pamela Pamphylie Pan Paname Panamá Panasonic
	  Pangée Pannonie Pantagruel Pantani Panthéon Pantin Panurge PAO Paola Paolo Papa Papeete
	  Papouasie-Nouvelle-Guinée Paracelse Paraguay Paramaribo Pareto Paris Parkinson Parme
	  Parque Parthie Parthénon Pas-de-Calais Pascal Pascale Passau Passy Pasternak Pasteur
	  Patagonie Paterne Patodi Patras Patrice Patricia Patrick Patrocle Patsy Patty Pau
	  Paul-Emile Paula Paule Paulette Pauli Paulin Paulina Pauline Pauling Paulo Pausanias
	  Pays-Bas Paz Pbit PCV PDF PDG Peano Pearl Pearson Peary Pedro Peggy Pelletier Peltier
	  Pendjari Pendragon Penh Penjab Pennsylvanie Penny Penthésilée Perceval Pergame Pergaud
	  Perl Perm Perpignan Perrault Perreux-sur-Marne Perrin Perrine Perse Persée Perséphone
	  Perth Perón Pesci Pessac Pete Peter Petit-Breton Petit-Quevilly Petrograd Peugeot
	  PGCD Phil Philadelphie Philalèthe Philibert Philip Philippa Philippe Philippeville
	  Phillips Philomène Philon Philémon Phnom Phobos Phoebe Phoenix PHP Phragmen Phrygie
	  Phœbé Phèdre Phénicie Piave PIB Pibit Pic Picard Picardie Picasso Piccard Pie Pierre
	  Pierre-Louis Pierre-Yves Pierrefitte-sur-Seine Pierrette Pierrick Pierrot Pietro
	  Pikine Pilate Pingeon Pinocchio Pinochet Pio Piotr Piper Pirandello Pise Pisidie
	  Pitot Pittsburgh Pizarro Piémont Placid Placide Plaisir Plancherel Planck Platon
	  Plessis-Robinson Pline Ploiesti Plotin Plovdiv Plutarque Pluton Plymouth PMA PME
	  Podgorica Poe Poincaré Pointe Pointe-Claire Pointe-à-Pitre Poirot-Delpech Poiré Poisson
	  Poitiers Poitou Poitou-Charentes Pol Pollock Polo Pologne Polybe Polynésie Pompidou
	  Pompéi Poméranie Pondichéry Pont Pont-Euxin Pontault-Combault Ponte Pontoise Pontryagin
	  Popper Porphyre Port Port-au-Prince Port-Gentil Portia Porto Porto-Novo Portugal
	  Poséidon Potemkine Potsdam Pouchkine Poutine Poznan PPCM Prague Praia Prairie Prandtl
	  Pre Pretoria Priam Priape Princeton Prisca Priscilla Priscille Pristina Privas Proche-Orient
	  Prokofiev Prolog Prométhée Prosper Protée Proudhon Proust Prouvé Provence Prudence
	  Prévert Ptolémée Puccini Puck Puebla Puiseux Pune Purcell Puteaux Puvis Puy-de-Dôme
	  PVC Pyongyang Pyrrha Pyrrhus Pyrénées Pyrénées-Atlantiques Pyrénées-Orientales Pythagore
	  Pâris Pégase Péguy Pékin Pélagie Péloponnèse Pénélope Pépin Pérec Périclès Périgord
	  Pérou Pétain Pétange Pétaouchnok Pétrarque Pétronille Pétula Pólya Qatar Queensland
	  Quentin Quercy Quetzalcóatl Quiberon Quichotte Quimper Quintilien Quirinal Quito
	  Québec R'n'B Rabat Rabelais Rabindranath Rachel Rachid Rachida Rachmaninov Racine
	  Radon Raffaella Ragnar Ragnarök Rajasthan RAM Ramallah Raman Rambouillet Ramon Ramsès
	  Randall Randstad Randy Rangoon Raoul Raphaël Raphaëlle Raphson Rapperswil-Jona Raquel
	  Ratisbonne RATP Rauch Raul Ravachol Ravel Ray Rayan Rayleigh Raymond Raymonde Raïssa
	  Reagan Rebecca Recife Reconquista Reggiani Regina Reginald Reich Reichstag Reidemeister
	  Reims Reiten Rellich Rembrandt Remich Remus Renaix Renan Renata Renaud Renault Rennes
	  René René Fallet Renée Repentigny RER Rett Retz Reykjavík Reynald Reynolds Rezé RFA
	  Rham Rhin Rhode Rhodes Rhodes-Extérieures Rhodes-Intérieures Rhodia Rhodésie Rhonda
	  Rhéa Rhénanie Rhénanie-du-Nord-Westphalie Rhénanie-Palatinat Rhétie Rhône Rhône-Alpes
	  RIB Rica Ricardo Riccardo Riccati Ricci Richard Richelieu Richmond Richter Rick Ricky
	  Riehen Riemann Riesz Riga Rigaud Rijs Rillieux-la-Pape Rimbaud Rimouski Rimsky-Korsakov
	  Ris-Orangis Rita Ritchie Ritt Rivers Rives Riviera Rivières Rixensart Riyad RMI RMIste
	  Roanne Rob Robert Robert-Louis Roberta Roberte Roberto Roberval Robespierre Robic
	  Robinson Roblès Roch Roche-sur-Yon Rochefort Rochefoucauld Rochelière Rochelle Rodez
	  Rodney Rodolphe Rodrigo Rodrigue Roeser Roger Rokhlin Roland Rolande Rolando Rolland
	  ROM Romagne Romain Romainville Romane Romanov Romans-sur-Isère Romaric Romberg Rome
	  Romulus Roméo Ron Ronald Ronan Roncevaux Ronnie Ronsard Roosevelt Rorschach Rosa
	  Rosario Rose Rose-Marie Roseline Roselyne Roselyse Rosemonde Rosewall Rosine Rosny-sous-Bois
	  Rossini Rostand Roswell Roth Rothschild Rotterdam Roubaix Rouen Rouergue Roulers
	  Rousseau Roussillon Roussin Rouyn-Noranda Rover Roxana Roxane Roxanne Roy Royaume-Uni
	  RTT Ruanda RUB Ruben Rubens Rubicon Ruby Rudolf Rudolph Rudy Rudyard Rueil-Malmaison
	  Ruhr Rumelange Runge Rungis Rupert Russell Russie Ruth Rutherford Rutishauser Rwanda
	  Râmâyana Réaumur Régine Régis Rémi Rémy Réunion Rûmî Saab Sabine Sablon Sabrina Sacha
	  Saddam Sade Sadi Safia Sagan Saguenay Saguenay–Lac-Saint-Jean Sahara Saint-André
	  Saint-Benoît Saint-Brieuc Saint-Bruno-de-Montarville Saint-Bénézet Saint-Chamond
	  Saint-Constant Saint-Cyr Saint-Cyr-l'École Saint-Denis Saint-Dizier Saint-Dié-des-Vosges
	  Saint-Empire Saint-Esprit Saint-Eustache Saint-Exupéry Saint-Gall Saint-Georges Saint-Germain-en-Laye
	  Saint-Herblain Saint-Hyacinthe Saint-Jacques-de-Compostelle Saint-Jean Saint-Jean-Baptiste
	  Saint-Joseph Saint-Josse-ten-Noode Saint-Just Saint-Jérôme Saint-Kitts-et-Nevis Saint-Lambert
	  Saint-Laurent-du-Var Saint-Leu Saint-Louis Saint-Lô Saint-Malo Saint-Marin Saint-Martin
	  Saint-Maur-des-Fossés Saint-Michel-sur-Orge Saint-Médard-en-Jalles Saint-Nazaire
	  Saint-Office Saint-Ouen Saint-Ouen-l'Aumône Saint-Patrick Saint-Paul Saint-Philippe
	  Saint-Pierre-et-Miquelon Saint-Pol-sur-Mer Saint-Priest Saint-Pétersbourg Saint-Quentin
	  Saint-Saëns Saint-Siège Saint-Sylvestre Saint-Sébastien-sur-Loire Saint-Trond Saint-Tropez
	  Saint-Verhaegen Saint-Vincent-et-les-Grenadines Saint-Étienne Saint-Étienne-du-Rouvray
	  Sainte-Foy-lès-Lyon Sainte-Geneviève-des-Bois Sainte-Hélène Sainte-Julie Sainte-Lucie
	  Sainte-Thérèse Saintes Saintonge Sakharov Salaberry-de-Valleyfield Saladin Salamanque
	  Salieri Salim Salima Salisbury Salle Sally Salma Salomon Salomé Salon-de-Provence
	  Salvador Salvatore Salzbourg Sam Samantha Samara Samarcande Samarie Sambre Sambreville
	  Samia Samir Samira Samoa Samothrace Samson Samsung Samuel Samy San Sanaa Sancerrois
	  Sandra Sandrine Sandy Sanem Sankara Sannois Sanofi Santa Santerre Santiago Santorin
	  Sapporo Saqqarah Sara Saragosse Sarah Sarajevo Sarcelles Sard Sardaigne Sardanapale
	  Sarkozy SARL Sarre Sarrebruck Sarreguemines Sarthe Sartre Sartrouville Sasha Saskatchewan
	  Sassandra Satan Saturne Saturnin Saul Saumur Saussure Savannah Savigny-le-Temple
	  Savoie Savonarole Sax Saxe Saxe-Anhalt Saxe-Cobourg Saïd Saône Saône-et-Loire Scandinavie
	  Scarlett Schaerbeek Schaffhouse Schauder Schengen Schiff Schifflange Schiller Schiltigheim
	  Schmitt Schnirelmann Schoelcher Schoenberg Schoendoerffer Schopenhauer Schoten Schottky
	  Schreier Schrödinger Schubert Schulmann Schumann Schumpeter Schur Schwartz Schwarz
	  Schwerin Schwytz Schwyz Schönberg Scipion Scott Scoville Scylla SDF SeaMonkey Seamus
	  Seat Seattle Sebastian Sedan Sega Seidel Seifert Seine Seine-et-Marne Seine-Maritime
	  Selena Selim Selma Seltz Semois Semprun Sendai Sens Sept-Îles Seraing Serbie Serena
	  Sergio Sergueï Servat Seth Seurat Severi Severiano Sevran Seychelles Seyne-sur-Mer
	  Shaanxi Shakespeare Shane Shanghai Shannon Shapiro Sharon Shaun Shawinigan Shawn
	  Sheila Shell Sheller Shelley Shelly Shenyang Shenzhen Sherbrooke Sherlock Sheryl
	  Shimura Shirley Shiva Shoah Shuman Shéhérazade Siam Sibelius Sibylle Sibérie Sichuan
	  Siddhartha Sidney Sidoine Sidon Sidonie Siegel Siegfried Siemens Sierpiński Sierra
	  Sigismond Sigmar Sigmund Sigourney Sigurd Sikasso Silas Silvio Silvère Silésie Simenon
	  Simon Simone Simpson Siméon Sinaï Singapour Singer Sion SIRET Sirius Sissy Sisyphe
	  Sixtine Skoda Skopje Slimane Slovaquie Slovénie SMIC Smith Smolensk SMS SNCF Sobolev
	  Socrate Sodome Sofia Sofiane Sogdiane Soignies Soissons Solange Soledad Solers Soleure
	  Soljenitsyne Sologne Solveig Solène Somalie Somerset Somme Sommerfeld Sonia Sony
	  Sophia Sophie Sophocle Sophonie Soraya Sorbonne Sorel-Tracy Soren SOS Sotteville-lès-Rouen
	  Soudan Soufflot Soufiane Soulage Soulages Souleymane Souriau Southampton Soutine
	  Spacek Spanghero Spartacus Sparte Spencer SPF Spinoza Spitz Split SPRL SRAS Sri SSII
	  Stacy Stains Staline Stalingrad Stanislas Stanley Stanleyville Stark Stasi Staël
	  Stefan Stefano Stein Steinbeck Steinhaus Stella Stendhal Stenmark Steph Stephan Stephen
	  Steven Stevenson Stieltjes Stirling Stivell Stockholm Stoke-on-Trent Stokes Stone
	  Strabon Stradivarius Strasbourg Strauss Stravinski Strejc Stu Stuart Sturm Stuttgart
	  Stéphan Stéphane Stéphanie Sucy-en-Brie Sud-Bandama Sud-Kivu Sud-Soudan Sudètes Sue
	  Suisse Sumatra Sumer Supérieur Surabaya Surcouf Suresnes Surinam Suriname Susan Susannah
	  Sussex Suzanne Suzette Suzuki Suzy Suède Suétone Svalbard Sven Sverdlovsk Svetlana
	  Sycorax Sydney Sylow Sylvain Sylvaine Sylvestre Sylvette Sylvia Sylviane Sylvie Sylvine
	  Sylvère Syracuse Syrie Szczecin São Sète Sèvre Sébastien Sébastopol Ségolène Sélène
	  Séléné Sémiramis Sémélé Sénèque Sénégal Sénégambie Séoul Séraphin Séraphine Sérapis
	  Séverin Séverine Sévigné Séville Tabitha Tachkent Tacite Tadjikistan Tagore Tahiti
	  Takeshi Talence Talleyrand Tallinn Tamagawa Tamara Tamerlan Tamise Tammy Tampico
	  Tananarive Tancarville Tancrède Tanger Tanguy Tania Tanit Tanya Tanzanie Tao Tara
	  Tarek Tarentaise Tarente Tarik Tarn Tarn-et-Garonne Tarquin Tarraconaise Tarski Tartempion
	  Tasmanie Tatiana Taurides Taverny Taylor Taïwan Tbilissi Tbit Tchad Tchaïkovski Tchebotarev
	  Tchekhov Tcheliabinsk Tchernobyl Tchécoslovaquie Tchéquie Tchétchénie Ted Teddy Tegucigalpa
	  Tel-Aviv Telemann Tenerife Tennessee Teotihuacán TER Teresa Teri Termonde Terre Terre-Neuve
	  Terrebonne Terrence Terri Terrible Terry Tertullien Tervuren Tesla Tess Tessa Tessin
	  Texas TGV Thaddée Thalie Thalès Thanatos Thanksgiving Thatcher Thaïlande Thea Thelma
	  Thessalie Thessalonique Thetford Theux Thiais Thibaud Thibault Thibaut Thierry Thiers
	  Thiès Thiéfaine Thiérache Thomas Thompson Thomson Thonon-les-Bains Thor Thoune Thoutmosis
	  Thucydide Thunderbird Thurgovie Thuringe Thèbes Thècle Théa Thémis Thémistocle Théo
	  Théodebert Théodora Théodore Théodoric Théodule Théophile Thérèse Thérésa Thésée
	  Thévenet Thévenin Tia Tianjin Tibet Tibit Tibre Tibère Tiers-Monde Tietze Tiffany
	  Tiger Tijuana Tikal Tim Timisoara Timor Timothy Timothée Timéo Tina Tino Tintoret
	  Tiphaine Tirana Tirlemont Titan Titania Titchmarsh Tite Tite-Live Titicaca Titien
	  Titouan Titus TMS TNT Tobias Tobie Tocqueville Tocquville Toda Todd Toeplitz Togo
	  Tokyo Tolkien Tolstoï Tolède Tom Tomba Tombouctou Tommy Tomé Tonga Tongres Toni Tony
	  Torelli Tori Toronto Torquemada Torr Torricelli Toscane Touba Toufik Toulon Toulouse
	  Toungouska Tour Touraine Tourcoing Tourette Tourgueniev Tournai Tournefeuille Tournier
	  Toussaint Tout-Paris Toutankhamon Toutatis Tower Toyota Trabant Tracey Tracy Trafalgar
	  Transnistrie Transylvanie Trappes-en-Yvelines Travis Tremblay-en-France Trentin-Haut-Adige
	  Tricia Trieste Trinity Trinité-et-Tobago Trintignant Triolet Tripoli Triptolème Tristan
	  Trois Trois-Rivières Trotski Troy Troyat Troyes Trudy Truman Très-Haut Tsahal Tshikapa
	  TTC Tubize Tucson Tudor Tulle Tulsa Tunguska Tunis Tunisie Turin Turing Turkménistan
	  Turner Turnhout Turquie Tutte Tuttlingen Tuvalu TVA Twain Tycho Tychonoff Tyler Typhaine
	  Tyrone Téhéran Télémaque Ténakourou Téo Térésa Téthys Uccle Ugo Ukraine Ulam Ulis
	  Ulm Ulrich Ulster Ulysse Umbriel UMTS UNESCO Ungava UNICEF Unicode Unilever UNIX
	  Urbain Uri URL URSS URSSAF Ursula Ursule Uruguay USA USB USD Ushuaïa Uster Utah Ute
	  Utique Utrecht Uélé Vadim Vaduz Vailland Val-d'Oise Val-d'Or Val-de-Marne Valais
	  Valenciennes Valentin Valentina Valentine Valentino Valentré Valeria Valette-du-Var
	  Vallauris Valmy Valois Valparaiso Valère Valérie Valérien Valéry Van Vancouver Vandœuvre-lès-Nancy
	  Vanina Vannes Vanoise Vanuatu Vanves Var Varennes Varna Varsovie Varuna Vassili Vassiliu
	  Vau Vauban Vaucluse Vaud Vaudreuil-Dorion Vaugirard Vaulx-en-Velin Vecchio Vegas
	  Velázquez Vendée Vendôme Venezuela Venise Venn Ventura Vera Verazzano Vercingétorix
	  Verdi Verdun Verhaeren Verlaine Vermeer Vermont Verne Verneuil Vernier Vernon Veronese
	  Veronika Versailles Vertou Verviers Vesoul Vespasien Vespucci Vesta Vexin Vialar
	  Vicki Vicky Victoire Victor Victoria Victoriaville Victorien Victorine VIe Vienne
	  Vierzon Vietnam Vietoris Vigenère Vigneault Vigneux-sur-Seine Vigo VIH VII VIIe VIII
	  Viktor Viktoria Vilaine Vilas Villefranche-sur-Saône Villejuif Villemomble
	  Villeneuve Villeneuve-d'Ascq Villeneuve-la-Garenne Villeneuve-Saint-Georges Villeneuve-sur-Lot
	  Villepinte Villeurbanne Villiers-le-Bel Villiers-sur-Marne Villon Vilnius Vilvorde
	  Vince Vincennes Vincent Vincenzo Vinci Vinciane Violaine Violette Viollet-le-Duc
	  Virasoro Virgile Virginia Virginie Virginie-Occidentale Virton Viry-Châtillon Vishnou
	  Vitali Vitebsk Vitoria Vitrolles Vitruve Vitry-sur-Seine Vittoria Vittorio Vitória
	  Vivendi Viviane Vivien VIᵉ Vladimir Vladivostok Vlaminck Voiron Volga Volkswagen
	  Voltaire Volterra Vosges VPN Vries VTC VTT Vve Vᵉ Véda Vélizy-Villacoublay Vénissieux
	  Vénétie Vérone Véronique Vésuve Wadowice Waerden Wagner Waldo Walhalla Walid Wallace
	  Wallonie Wally Walmart Walras Walt Walter Wantzel Waregem Waremme Waring Warren Washington
	  Wassim Waterloo Watermael-Boitsfort Watson Watt Watteau Wattrelos Wavre Wayne Weaver
	  Wedderburn Wegener Weierstrass Weimar Weismuller Wellington Wells Wenceslas Wendy
	  Wesley Wessex Westende Westerlo Westhoek Westinghouse Westminster Westmount Westphalie
	  Wevelgem Weyl Wheatstone Whitehead Whitehorse Whitney Wichita Wiener Wiesbaden Wiesel
	  Wigner Wikipédia Wilbur Wilde Wilfred Wilfrid Wilfried Wilhelm Will Willa Willebroek
	  Williams Willie Willy Wilma Wilson Windhoek Windows Winnipeg Winston Winterthur Wirsung
	  Witt Wittgenstein Wolfgang Wolinski Woluwe-Saint-Lambert Woluwe-Saint-Pierre Wolverhampton
	  Woody Woolf Wroclaw Wuhan Wuppertal Wurtemberg Wyoming Xander Xavier Xavière Xenia
	  Xinjiang XXe XXXe XXXVe XXXVIe XXXVIᵉ XXXVᵉXXXᵉ XXᵉ Xᵉ Xénophane Xénophon
	  Yahvé Yahweh Yakov Yalta Yamabe Yamina Yamoussoukro Yanis Yann Yanne Yannick Yannis
	  Yasmina Yasmine Yasser Yassine Yazid Ybit Yellowknife Yennenga Yerres Yggdrasil YHWH
	  Yio Yoan Yoann Yohan Yohann Yokohama Yolaine Yolanda Yolande Yonne York Youcef Yougoslavie
	  Young Yourcenar Youri Youssef Youssouf Ypres Yser Yseult Yucatán Yukon Yvain Yvan
	  Yverdon-les-Bains Yves Yvette Yvon Yvonne Yémen Zach Zacharie Zachary Zack Zagreb
	  Zakaria Zambie Zambèze Zarathoustra Zariski Zatopek Zaventem Zaïre Zbit Zedelgem
	  Zele Zemst Zener ZEP Zermelo Zeus Zibit Zimbabwe Zina Zineb Zio Zita Zoersel Zoey
	  Zola Zonhoven Zorn Zoroastre Zosime Zottegem Zoug Zoé ZUP Zurich Zwevegem Zwin Zwingli
	  Zélande Zénon
	  /;
	return \%proper_nouns;
}

# From http://www.dicollecte.org - Césure 3.0
sub _get_official_fr_patterns {
	return [
		qw /
		  2'2        .a4        'a4        .â4        'â4        ab2h       a1bî       abî1me
		  abî2ment.  .a1b2r     'a1b2r     .ab1ré     'ab1ré     .ab3réa    'ab3réa    ab1se
		  ab3sent.   abs1ti     absti1ne   absti3nent. ac1ce      ac3cent.   ac1q       acquies1ce
		  acquies4cent. ad2h       aè1d2r     a1è2d1re   .ae3s4c2h  'ae3s4c2h  a1g2n      .a1g2n
		  'a1g2n     .ag1na     'ag1na     .a2g3nat   'a2g3nat   ag1no      a2g3nos    ai1me
		  ai2ment.   a1la       a2l1al1gi  al1co      1alcool    a1ma       amal1ga    amalga1me
		  amalga2ment. â1me       â2ment.    .a1mi      'a1mi      .ami1no    'ami1no    .amino1a2c
		  'amino1a2c .a1na      'a1na      .ana3s4t2r 'ana3s4t2r a1ne       anes1t2h   anest1hé
		  1a2nesthé1si a1ni       ani1me     ani2ment.  an1ti      .an1ti     'an1ti     .anti1a2
		  'anti1a2   .anti1e2   'anti1e2   .anti1é2   'anti1é2   .anti2en1ne 'anti2en1ne anti1fe
		  antifer1me antifer3ment. .anti1s2   'anti1s2   a1po       .a1po      'a1po      .apo2s3ta
		  'apo2s3ta  apo2s3t2r  ap1pa      appa1re    appa3rent. ar1c2h     arc1hi     archié1pi
		  archi1é2pis .ar1de     .ar3dent.  .ar1ge     'ar1ge     .ar3gent.  'ar3gent.  ar1me
		  ar2ment.   ar1mi      armil5l    .ar1pe     'ar1pe     .ar3pent.  'ar3pent.  as1me
		  as2ment.   .as2ta     'as2ta     as1t2r     a2s3t1ro   au1me      au2ment.   a1vi
		  avil4l     1ba        .1ba       1bâ        .bai1se    .baise1ma  .bai2se3main 1be
		  1bé        1bè        1bê        4be.       2bent.     4bes.      1bi        .1bi
		  1bî        .bi1a2c    .bi1a2t    .bi1au     .bio1a2    .bi2s1a2   .bi1u2     1b2l
		  b1le       4b4le.     2b2lent.   4b4les.    1bo        1bô        bou1me     bou2ment.
		  bou1ti     boutil3l   1b2r       b1re       4b4re.     2b2rent.   4b4res.    b1ru
		  bru1me     bru2ment.  1bu        1bû        1by        1ç         1ca        1câ
		  ca3ou3t2   ca1pi      capil3l    ca1rê      carê1me    carê2ment. c1ci       cci1de
		  cci3dent.  1ce        1cé        1cè        1cê        4ce.       2cent.     4ces.
		  1c2h       .1c2h4     4ch.       2chb       c1he       .c1hè      4c4he.     2chent.
		  4c4hes.    che1vi     chevil4l   .chè1v2r   .chèv1re   .chèvre1fe .chèvrefeuil2l .chè2vre3feuil1le
		  2chg       c1hi       chien1de   chien3dent. ch2l       ch1le      4ch4le.    4ch4les.
		  ch1lo      chlo1ra    chlo2r3a2c chlo1ré    chlo2r3é2t 2chm       2chn       2chp
		  ch2r       ch1re      4ch4re.    4ch4res.   ch1ro      chro1me    chro2ment. 2chs
		  2cht       2chw       1ci        .1ci       1cî        cil3l      .ci1sa     .ci2s1alp
		  1c2k       4ck.       2ckb       c1ke       4c4ke.     2c2kent.   4c4kes.    2ckf
		  2ckg       2c1k3h     2ckp       2cks       2ckt       1c2l       c1la       cla1me
		  cla2ment.  c1le       4c4le.     2c2lent.   4c4les.    1co        .1co       1cô
		  co1acc     co1ac1q    co1a2d     co1ap      co1ar      coas1so    co1assoc   coas1su
		  co1assur   co1au      co1ax      1cœ        co1é2      co1ef      co1en      co1ex
		  co1g2n     cog1ni     co2g3ni1ti .com1me    .com3ment. com1pé     compé1te   compé3tent.
		  .con4      con1fi     confi1de   confi3dent. con1ni     conni1ve   conni3vent. .cons4
		  con1ti     conti1ne   conti3nent. contin1ge  contin3gent. .con1t2r   .cont1re   .contre1ma
		  .contremaî1t2r .cont1re3maît1re .contre1s2c co1nu      co2nurb    .co1o2     .coo1li    .co2o3lie
		  cor1pu     corpu1le   corpu3lent. 1c2r       c1re       4c4re.     2c2rent.   4c4res.
		  1cu        .1cu       1cû        .cul4      cur1re     cur3rent.  1cy        cy1ri
		  cyril3l    1d2'2      1da        .1da       1dâ        .da1c2r    .dac1ry    .dacryo1a2
		  da1me      da2ment.   d1d2h      1de        1dé        .1dé       1dè        1dê
		  4de.       .dé1a2     dé1ca      déca1de    déca3dent. .dé1io     2dent.     .dé1o2
		  .dé2s      4des.      .dé1sa     .dé3s2a3c2r .dés2a3m   .dé3s2as1t2r .désa1te   .dé3s2a3tell
		  .dé3s2c    .dé1se     .dé2s1é2   .dé3s2é3g2r .désen1si  .dé3s2ensib .dé3s2ert  .dé3s2exu
		  .dé2s1i2   .dé3s2i3d  .dé3s2i3g2n .dé3s2i3li .dési1ne   .dé3s2i3nen .dé3s2in1vo .dé3s2i3r
		  .dé3s2ist  .dé1so     .1dé3s2o3dé .dé2s1œ    .dé3s2o3l  .déso1pi   .dé3s2o3pil .dé3s2orm
		  .dé3s2orp  .dé3s2ou1f2r .dé3s2p    .dé3s2t    .dé1su     .dé2s1u2n  dé1t2r     dét1ri
		  détri1me   détri3ment. d1ha       3d2hal     d1ho       3d2houd    1di        .1di
		  1dî        .di1a2cé   .dia1ci    .di1a2cid  .di1ald    .di1a2mi   dia1p2h    diaph2r
		  diaph1ra   diaphrag1me diaphrag2ment. .dia1to    .di1a2tom  .di1e2n    di1li      dili1ge
		  dili3gent. dis1co     di2s3cop   .di2s3h    dis1si     dissi1de   dissi3dent. dis1ti
		  distil3l   d1le       2d2lent.   1do        .1do       1dô        .do1le     .do3lent.
		  1d2r       d1re       4d4re.     2d2rent.   4d4res.    d1s2       1du        1dû
		  1dy        .1dy       .dy2s3     .dy2s1a2   .dy2s1i2   .dy2s1o2   .dy2s1u2   .e4
		  'e4        .é4        'é4        .è4        'è4        .ê4        'ê4        é1ce
		  é3cent.    é1ci       éci1me     éci2ment.  é1cu       écu1me     écu2ment.  é1de
		  é3dent.    éd2hi      é1d2r      éd1ri      1é2drie    édri1q     1é2drique  é1le
		  é1lé       1é2lec1t2r élé1me     1é2lément  é1li       éli1me     éli2ment.  é1lo
		  élo1q      élo3quent. è1me       è2ment.    é1mi       .é1mi      émil4l     .émi1ne
		  .émi3nent. .e1n1a2    'e1n1a2    é1ne       1é2nerg    e1ni       é1ni       éni1te
		  éni3tent.  e2n1i2v2r  .e1n1o2    'e1n1o2    en1t2r     ent1re     entre1ge   entre3gent.
		  é1pi       épis1co    épi2s3cop  épi3s4co1pe é1q        é3quent.   équi1po    équipo1te
		  équipo3tent. équi1va    équiva1le  équiva4lent. é1re       é3rent.    er1me      er2ment.
		  es1ce      es3cent.   e2s3c2h    es1co      e2s3cop    es1ti      esti1me    esti2ment.
		  .eu2r1a2   'eu2r1a2   eus1ta     eu1s2tat   ex1t2r     ext1ra1    extra2c    extra2i
		  1fa        1fâ        fa1me      fa2ment.   1fe        1fé        1fè        1fê
		  4fe.       fé1cu      fécu1le    fécu3lent. 2fent.     4fes.      1fi        1fî
		  fi1c2h     fic1hu     fichu1me   fichu3ment. fir1me     fir2ment.  1f2l       f1la
		  flam1me    flam2ment. f1le       4f4le.     2f2lent.   4f4les.    1fo        1fô
		  1f2r       f1re       4f4re.     2f2rent.   4f4res.    f1ri       fri1ti     fritil3l
		  f1s2       1fu        1fû        fu1me      fu2ment.   1fy        1ga        1gâ
		  1ge        .1ge       1gé        1gè        1gê        4ge.       .gem1me    .gem2ment.
		  2gent.     4ges.      1g2ha      1g2he      1g2hi      1g2ho      1g2hy      1gi
		  1gî        gil3l      1g2l       g1le       4g4le.     2g2lent.   4g4les.    1g2n
		  g1ne       4g4ne.     2g2nent.   4g4nes.    1go        1gô        1g2r       g1ra
		  gram1me    gram2ment. gran1di    grandi1lo  grandilo1q grandilo3quent. g1re       4g4re.
		  2g2rent.   4g4res.    g1s2       1gu        1gû        4gue.      2guent.    4gues.
		  1gy        1ha        1hâ        1he        1hé        1hè        1hê        4he.
		  hé1mi      hémi1é     hé1mo      hémo1p2t   4hes.      1hi        1hî        hil3l
		  1ho        1hô        1hu        1hû        hu1me      hu2ment.   1hy        hy1pe
		  hype4r1    hype1ra2   hype1re2   hype1ré2   hype1ri2   hype1ro2   hypers2    hype1ru2
		  hy1po      hypo1a2    hypo1e2    hypo1é2    hypo1i2    hypo1o2    hypo1s2    hypo1u2
		  .i4        'i4        .î4        'î4        i1al1gi    iar1t2h    i1arth2r   i1b2r
		  ib1ri      ibril3l    iè1d2r     i1è2d1re   .i1g2n     'i1g2n     .i2g3né    'i2g3né
		  .i2g3ni    'i2g3ni    il2l       im1ma      imma1ne    imma3nent. im1mi      immi1ne
		  immi3nent. immis1ce   immis4cent. im1po      impo1te    impo3tent. im1pu      impu1de
		  impu3dent. .i1n1a2    'i1n1a2    .ina1ni    'ina1ni    .in2a3nit  'in2a3nit  .inau1gu
		  'inau1gu   .in2augur  'in2augur  in1ci      inci1de    inci3dent. in1di      indi1ge
		  indi3gent. in1do      indo1le    indo3lent. in1du      indul1ge   indul3gent. .i1n1e2
		  'i1n1e2    .i1n1é2    'i1n1é2    .inef1fa   'inef1fa   .in2effab  'in2effab  .iné1lu
		  'iné1lu    .in2é3luc1ta 'in2é3luc1ta .iné1na    'iné1na    .in2é3nar1ra 'in2é3nar1ra .in2ept
		  'in2ept    .in2er     'in2er     .in2exo1ra 'in2exo1ra in1fo      infor1ma   1informat
		  .i1n1i2    'i1n1i2    .ini1mi    'ini1mi    .in2i3mi1ti 'in2i3mi1ti .in2i3q    'in2i3q
		  .in2i3t    'in2i3t    in1no      inno1ce    inno3cent. .i1n1o2    'i1n1o2    .ino1cu
		  'ino1cu    .in2o3cul  'in2o3cul  .in2ond    'in2ond    in1so      inso1le    inso3lent.
		  .ins1ta    'ins1ta    .in1s2tab  'in1s2tab  ins1ti     instil3l   in1te      .in1te
		  'in1te     intel1li   intelli1ge intelli3gent. .inte4r3   'inte4r3   .inte1ra2  'inte1ra2
		  .inte1re2  'inte1re2  .inte1ré2  'inte1ré2  .inte1ri2  'inte1ri2  .inte1ro2  'inte1ro2
		  .inters2   'inters2   .inte1ru2  'inte1ru2  in1ti      inti1me    inti2ment. .i1n1u2
		  'i1n1u2    .in2uit    'in2uit    .in2u3l    'in2u3l    io1a2ct    i1oxy      is1ce
		  is3cent.   i1s2c2h    i2s3c1hé   isc1hi     i2s3chia   i2s3chio   is1ta      i1s2tat
		  i1va       iva1le     iva3lent.  1j         ja1ce      ja3cent.   4je.       2jent.
		  4jes.      2jk        1ka        1kâ        1ke        1ké        1kè        1kê
		  4ke.       2kent.     4kes.      1k2h       .1k2h4     4kh.       1ki        1kî
		  1ko        1kô        1k2r       1ku        1kû        1ky        1la        .1la
		  1là        1lâ        .la1te     .la3tent.  la1w2r     la2w3re    1le        1lé
		  1lè        1lê        4le.       2lent.     4les.      1li        1lî        lil3l
		  l1li       l3lion     l1lu       llu1me     llu2ment.  l1me       l2ment.    1lo
		  1lô        l1s2t      1lu        1lû        1ly        1ma        .1ma       1mâ
		  .ma2c3k    .ma1c2r    .mac1ro    .macro1s2c .ma1g2n    .mag1ni    .magni1ci  .ma2g3nici1de
		  .magni1fi  .magnifi1ca .ma2g3nificat .mag1nu    .ma2g3num  .ma1la     .mala1d2r  .malad1re
		  .ma2l1a2dres .ma2l1a2d1ro .ma2l1ai1sé .ma2l1ap   .ma2l1a2v  .ma1le     .ma2l1en   .ma1li
		  .ma2l1int  .ma1lo     .ma2l1oc   .ma2l1o2d  .ma2r1x    1me        1mé        .1mé
		  1mè        1mê        4me.       mé1co      mécon1te   mécon3tent. .mé1go     .mé2g1oh
		  4mes.      .mé2sa     .mé3san    .mé1se     .mé2s1es   .mé2s1i    .mé1su     .mé2s1u2s
		  .mé1ta     .mé1ta1s2ta 1mi        .1mi       1mî        mil3l      .mil3l     mil1le
		  mil4let    .mil1li    .milli1am  mi1me      mi2ment.   mit1te     mit3tent.  m1né
		  m1nè       1m2né1mo   1m2nès     1m2né1si   1mo        .1mo       1mô        1mœ
		  mo1no      .mo1no     .mono1a2   .mono1e2   .mono1é2   .mono1i2   .mono1ï2dé .mono1o2
		  .mono1s2   .mono1u2   mono1va    monova1le  monova3lent. mon1t2r    mont1ré    mon2t3réal
		  moye1nâ    moye2n1â2g m1s2       1mu        1mû        mu1ni      muni1fi    munifi1ce
		  munifi3cent. 1my        1na        1nâ        1ne        1né        1nè        1nê
		  4ne.       2nent.     4nes.      1ni        1nî        1no        .1no       1nô
		  1nœ        .no1no     .no2n1obs  n1sa       n3s2at.    n3s2ats.   1nu        1nû
		  nu1t2r     nut1ri     nutri1me   nutri3ment. n1x        1ny        .o4        'o4
		  .ô4        'ô4        o1b2l      ob1lo      o2b3long   oc1te      1octet     o1d2l
		  oè1d2r     o1è2d1re   o1g2n      og1no      ogno1mo    o2g3nomo1ni o2g3no1si  o1io1ni
		  om1bu      ombud2s3   ô1me       ô2ment.    om1me      om2ment.   om1ni      omni1po
		  omnipo1te  omnipo3tent. omni1s2    .on1gu     'on1gu     .on3guent. 'on3guent. o1pu
		  opu1le     opu3lent.  or1me      or2ment.   os1ta      o1s2tas    o1s2tat    os1té
		  o1s2té1ro  os1ti      o1s2tim    os1to      o1s2tom    os1t2r     ost1ra     o1s2trad
		  o1s2tra1tu ost1ri     ostric1ti  o1s2triction .oua1ou    'oua1ou    .o1vi      'o1vi
		  .ovi1s2c   'ovi1s2c   oxy1a2     1pa        .1pa       1pâ        pa1lé      paléo1é2
		  .pa1na     .pa2n1a2f  .pa2n1a2mé .pa2n1a2ra .pa1ni     .pa2n1is   .pa1no     .pa2n1o2p2h
		  .pa2n1opt  pa1pi      papil2l    papil3la   papil3le   papil3li   papil1lo   papil3lom
		  .pa1ra     .para1c2h  .pa2r1a2c1he .pa2r1a2c1hè .para1s2   .pa1re     .pa3rent.  .pa1r2h
		  .pa2r3hé   .pa1te     .pa3tent.  1pe        .1pe       1pé        .1pé       1pè
		  1pê        4pe.       2pent.     .pen2ta    pé1nu      pé2nul     .pe4r      .pe1r1a2
		  pé1ré      .pe1r1e2   .pe1r1é2   pé1r2é2q   pe1r3h     .pé1ri     .pe1r1i2   .péri1os
		  .péri1s2   .péri2s3s  .péri2s3ta .péri1u2   per1ma     perma1ne   perma3nent. .pe1r1o2
		  per1ti     perti1ne   perti3nent. .pe1r1u2   4pes.      1p2h       .1p2h4     4ph.
		  .p1ha      .pha1la    .phalan3s2t p1he       4p4he.     2phent.    4p4hes.    ph2l
		  ph1le      4ph4le.    4ph4les.   2phn       p1ho       pho1to     photo1s2   ph2r
		  ph1re      4ph4re.    4ph4res.   2phs       2pht       ph1ta      3ph2ta1lé  ph1ti
		  3ph2tis    1pi        1pî        pi1ri      piril3l    1p2l       .1p2l      p1le
		  4p4le.     2p2lent.   4p4les.    p1lu       .p1lu      plu1me     plu2ment.  .plu1ri
		  .pluri1a   p1ne       1p2né      1p2neu     1po        .1po       1pô        poas1t2r
		  po1ast1re  po1ly      poly1a2    poly1e2    poly1é2    poly1è2    poly1i2    poly1o2
		  poly1s2    poly1u2    poly1va    polyva1le  polyva3lent. .pon1te    .pon2tet   .pos2t3h
		  .pos1ti    .pos2t1in  .pos2t1o2  .pos2t3r   .post1s2   1p2r       .1p2r      p1re
		  p1ré       .p1ré      4p4re.     .pré1a2    .pré2a3la  .pré2au    .pré1e2    .pré1é2
		  préé1mi    préémi1ne  préémi3nent. .pré1i2    2p2rent.   .pré1o2    .pré1s2    4p4res.
		  pré1se     pré3sent.  .pré1u2    p1ri       pri1va     privat1do  privatdo1ce privatdo3cent.
		  privatdo1ze privatdo3zent. p1ro       .p1ro      .pro1é2    proé1mi    proémi1ne  proémi3nent.
		  .pro1g2n   .prog1na   .pro2g3na1t2h .pro1s2cé  pros1ta    pro2s3tat  .prou3d2h  p1ru
		  pru1de     pru3dent.  p1sy       .p1sy      1p2sy1c2h  .1p2sy1c2h .psyc1ho   .psycho1a2n
		  p1té       p1tè       1p2tér     1p2tèr     1pu        .1pu       1pû        .pud1d2l
		  pu1g2n     pug1na     pugna1b2l  pu2g3nab1le pu2g3nac   pu1pi      pupil3l    pu1si
		  pusil3l    1py        1q         qua1me     qua2ment.  4que.      2quent.    4ques.
		  1ra        1râ        ra1di      radio1a2   rai1me     rai3ment.  ra1me      ra2ment.
		  r1ci       rcil4l     1re        .1re       1ré        .1ré       1rè        1rê
		  4re.       .ré1a2     .ré2a3le   .réa1li    .ré2a3lis  .ré2a3lit  .ré2aux    .ré1e2
		  .ré1é2     .ré2el     .ré2er     .ré2èr     ré1ge      ré3gent.   .ré1i2     .ré2i3fi
		  re1le      re3lent.   re1li      reli1me    reli2ment. ré1ma      réma1ne    réma3nent.
		  2rent.     .ré1o2     re1pe      re3pent.   .re1s2     4res.      .res1ca    .re2s3cap
		  .res1ci    .re2s3ci1si .re2s3ci1so .res1co    .re2s3cou  .res1c2r   .re2s3c1ri .res1pe
		  .re2s3pect .res1pi    .re2s3pir  .res1p2l   .resp1le   .re2s3plend .res1po    .re2s3pons
		  .res1q     .re2s3quil .re2s3s    .res1se    .res3sent. .re2s3t    .res1ta    .re3s4tab
		  .re3s4tag  .re3s4tand .re3s4tat  .res1té    .re3s4tén  .re3s4tér  .res1ti    .re3s4tim
		  .re3s4tip  .res1to    .re3s4toc  .re3s4top  .re3s4t2r  .rest1re   .re4s5trein .rest1ri
		  .re4s5trict .re4s5trin .re3s4tu   .re3s4ty   ré1su      résur1ge   résur3gent. ré1ti
		  réti1ce    réti3cent. .ré1t2r    .rét1ro    .rétro1a2  .réu2      .ré2uss    1r2h
		  r1he       4r4he.     4r4hes.    2r3heur    r1hy       2r3hy1d2r  1ri        1rî
		  ri1me      ri2ment.   rin1ge     rin3gent.  r1mi       rmil4l     1ro        1rô
		  1ru        1rû        ru1le      ru3lent.   1ry        ry1t2h     ry2thm     ryth1me
		  ryth2ment. 1sa        .1sa       1sâ        .sar1me    .sar3ment. s1ca       1s2ca1p2h
		  1s2c2h     .1s2c2h4   4s4ch.     sc1he      4s4c4he.   4s4c4hes.  2s2chs     s1c2l
		  sc1lé      1s2clér    s1co       1s2cop     1se        .1se       1sé        1sè
		  1sê        4se.       se1mi      semil4l    2sent.     ser1ge     ser3gent.  .ser1me
		  .ser3ment. ser1pe     ser3pent.  4ses.      ses1q      sesqui1a2  .seu2le    1s2h
		  .1s2h4     4sh.       s1he       4s4he.     2shent.    4s4hes.    2shm       s1ho
		  2s3hom     2shr       2shs       1si        1sî        s1la       sla1lo     slalo1me
		  slalo2ment. 1s2lav     s1lo       1s2lov     1so        .1so       1sô        1sœ
		  .sou1ve    .sou3vent. s1pa       spa1ti     1s2patia   s1pe       1s2perm    s1p2h
		  sp1hé      sp1hè      1s2phér    1s2phèr    s1pi       1s2piel    spi1ro     1s2piros
		  s1po       1s2por     spo1ru     sporu1le   sporu4lent. s1ta       .s1ta      .sta2g3n
		  stan1da    1s2tandard s1te       s1té       1s2tein    sté1ré     stéréo1s2  s1ti
		  .s1ti      1s2tigm    .stil3l    s1to       1s2to1c2k  sto1mo     1s2tomos   s1t2r
		  st1ro      1s2tro1p2h st1ru      1s2truc1tu s1ty       1s2ty1le   1su        .1su
		  1sû        .su2b1a2   .su3b2alt  .su2b1é2   .su3b2é3r  .su1bi     .su2b1in   su1b2l
		  .su1b2l    sub1li     .sub1li    subli1me   subli2ment. .subli1mi  .su2b3limin .su2b3lin
		  .su2b3lu   sub1s2     .su1bu     .su2b1ur   suc1cu     succu1le   succu3lent. su1me
		  su2ment.   su1pe      supe4r1    supe1ro2   supers2    su1ra      .su2r1a2   su3r2ah
		  .su3r2a3t  su1ré      .su2r1e2   .su2r1é2   .su3r2eau  .su3r2ell  suré1mi    surémi1ne
		  surémi3nent. .su3r2et   .su2r3h    .su1ri     .su2r1i2m  .su2r1inf  .su2r1int  .su1ro
		  .su2r1of   .su2r1ox   1sy        .1sy       .syn1g2n   .syng1na   .syn2g3na1t2h 1ta
		  .1ta       1tà        1tâ        ta1c2h     tac1hy     tachy1a2   .ta1le     .ta3lent.
		  ta1me      ta2ment.   tan1ge     tan3gent.  t1c2h      tc1hi      tchin3t2   1te
		  1té        1tè        1tê        4te.       té1lé      télé1e2    télé1i2    télé1o2b
		  télé1o2p   télé1s2    tem1pé     tempé1ra   tempéra1me tempéra3ment. 2tent.     ter1ge
		  ter3gent.  4tes.      tes1ta     testa1me   testa3ment. 1t2h       .1t2h4     4th.
		  t1he       4t4he.     ther1mo    thermo1s2  4t4hes.    2t3heur    2thl       2thm
		  2thn       th2r       th1re      4th4re.    4th4res.   th1ri      thril3l    2ths
		  1ti        1tî        1to        1tô        to1me      to2ment.   tor1re     tor3rent.
		  1t2r       .1t2r      t1ra       tran2s1a2  tran3s2act tran3s2ats tran2s3h   tran2s1o2
		  tran2s3p   trans1pa   transpa1re transpa3rent. tran2s1u2  t1re       4t4re.     2t2rent.
		  4t4res.    t1ri       .t1ri      .tri1a2c   .tri1a2n   .tri1a2t   tri1de     tri3dent.
		  .tri1o2n   t1ru       tru1cu     trucu1le   trucu3lent. t1t2l      1tu        1tû
		  tu1me      tu2ment.   tung2s3    tur1bu     turbu1le   turbu3lent. 1ty        .u4
		  'u4        .û4        'û4        u1ci       ucil4l     ue1vi      uevil4l    u1ni
		  uni1a2x    uni1o2v    u2s3t2r    u1vi       uvil4l     1va        1vâ        va1ci
		  vacil4l    va1ni      vanil2l    vanil1li   vanil3lin  vanil3lis  1ve        1vé
		  1vè        1vê        4ve.       vé1lo      vélo1s2ki  ve1ni      veni1me    veni2ment.
		  2vent.     ven1t2r    vent1ri    ventri1po  ventripo1te ventripo3tent. 4ves.      1vi
		  1vî        vi1di      vidi1me    vidi2ment. vil3l      1vo        1vô        vol1ta
		  vol2t1amp  1v2r       v1re       4v4re.     2v2rent.   4v4res.    1vu        1vû
		  1vy        1wa        wa2g3n     1we        4we.       2went.     4wes.      1wi
		  1wo        1w2r       1wu        2xent.     xil3l      .y4        'y4        y1al1gi
		  y1as1t2h   ys1to      y1s2tom    1za        1ze        1zé        1zè        4ze.
		  2zent.     4zes.      1zi        1zo        1zu        1zy        2’2        ’a4
		  4a-        .á4        'á4        ’á4        4á-        .à4        'à4        ’à4
		  4à-        ’â4        4â-        .å4        'å4        ’å4        4å-        .ä4
		  'ä4        ’ä4        4ä-        .ã4        'ã4        ’ã4        4ã-        -5a4
		  -5á4       -5à4       -5â4       -5å4       -5ä4       -5ã4       abî2ment-  ’a1b2r
		  -5a1b2r    ’ab1ré     -5ab1ré    ’ab3réa    -5ab3réa   ab3sent-   absti3nent- ac3cent-
		  acquies4cent- .æ4        'æ4        ’æ4        4æ-        -5æ4       ’ae3s4c2h  -5ae3s4c2h
		  ’a1g2n     -5a1g2n    ’ag1na     -5ag1na    ’a2g3nat   -5a2g3nat  ai2ment-   amalga2ment-
		  â2ment-    ’a1mi      -5a1mi     ’ami1no    -5ami1no   ’amino1a2c -5amino1a2c ’a1na
		  -5a1na     ’ana3s4t2r -5ana3s4t2r ani2ment-  ’an1ti     -5an1ti    ’anti1a2   -5anti1a2
		  ’anti1e2   ’anti1é2   -5anti1e2  -5anti1é2  ’anti2en1ne -5anti2en1ne antifer3ment- ’anti1s2
		  -5anti1s2  ’a1po      -5a1po     ’apo2s3ta  -5apo2s3ta appa3rent- -5ar1de    -ar3dent-
		  .ar3dent-  -5ar3dent. ’ar1ge     -5ar1ge    -ar3gent-  .ar3gent-  'ar3gent-  ’ar3gent-
		  ’ar3gent.  -5ar3gent. ar2ment-   ’ar1pe     -5ar1pe    -ar3pent-  .ar3pent-  'ar3pent-
		  ’ar3pent-  ’ar3pent.  -5ar3pent. as2ment-   ’as2ta     -5as2ta    au2ment-   .b4
		  'b4        ’b4        4b-        -5b4       -5bai1se   -5baise1ma -5bai2se3main 4be-
		  2bent-     4bes-      -5bi1a2c   -5bi1a2t   -5bi1au    -5bio1a2   -5bi2s1a2  -5bi1u2
		  4b4le-     2b2lent-   4b4les-    bou2ment-  4b4re-     2b2rent-   4b4res-    bru2ment-
		  .c4        'c4        ’c4        4c-        .ç4        'ç4        ’ç4        4ç-
		  -5c4       -5ç4       carê2ment- cci3dent-  4ce-       2cent-     4ces-      4ch-
		  4c4he-     -5c1hè     2chent-    4c4hes-    -5chè1v2r  -5chèv1re  -5chèvre1fe -5chèvrefeuil2l
		  -5chè2vre3feuil1le chien3dent- 4ch4le-    4ch4les-   4ch4re-    4ch4res-   chro2ment- -5ci1sa
		  -5ci2s1alp 4ck-       4c4ke-     2c2kent-   4c4kes-    cla2ment-  4c4le-     2c2lent-
		  4c4les-    -5com1me   -com3ment- .com3ment- -5com3ment. compé3tent- -5con4     confi3dent-
		  conni3vent- -5cons4    conti3nent- contin3gent- -5con1t2r  -5cont1re  -5contre1ma -5contremaî1t2r
		  -5cont1re3maît1re -5contre1s2c -5co1o2    -5coo1li   -5co2o3lie corpu3lent- 4c4re-     2c2rent-
		  4c4res-    -5cul4     cur3rent-  1d2’2      .d4        'd4        ’d4        4d-
		  .ð4        'ð4        ’ð4        4ð-        -5d4       -5ð4       -5da1c2r   -5dac1ry
		  -5dacryo1a2 da2ment-   4de-       -5dé1a2    déca3dent- -5dé1io    2dent-     -5dé1o2
		  4des-      -5dé2s     -5dé1sa    -5dé3s2a3c2r -5dés2a3m  -5dé3s2as1t2r -5désa1te  -5dé3s2a3tell
		  -5dé3s2c   -5dé1se    -5dé2s1é2  -5dé3s2é3g2r -5désen1si -5dé3s2ensib -5dé3s2ert -5dé3s2exu
		  -5dé2s1i2  -5dé3s2i3d -5dé3s2i3g2n -5dé3s2i3li -5dési1ne  -5dé3s2i3nen -5dé3s2in1vo -5dé3s2i3r
		  -5dé3s2ist -5dé1so    -5dé2s1œ   -5dé3s2o3l -5déso1pi  -5dé3s2o3pil -5dé3s2orm -5dé3s2orp
		  -5dé3s2ou1f2r -5dé3s2p   -5dé3s2t   -5dé1su    -5dé2s1u2n détri3ment- -5di1a2cé  -5dia1ci
		  -5di1a2cid -5di1ald   -5di1a2mi  diaphrag2ment- -5dia1to   -5di1a2tom -5di1e2n   dili3gent-
		  -5di2s3h   dissi3dent- 2d2lent-   -5do1le    -do3lent-  .do3lent-  -5do3lent. 4d4re-
		  2d2rent-   4d4res-    -5dy2s3    -5dy2s1a2  -5dy2s1i2  -5dy2s1o2  -5dy2s1u2  ’e4
		  4e-        ’é4        4é-        ’è4        4è-        ’ê4        4ê-        .ë4
		  'ë4        ’ë4        4ë-        -5e4       -5é4       -5è4       -5ê4       -5ë4
		  é3cent-    éci2ment-  écu2ment-  é3dent-    éli2ment-  élo3quent- è2ment-    -5é1mi
		  -5émi1ne   -émi3nent- .émi3nent- -5émi3nent. ’e1n1a2    -5e1n1a2   éni3tent-  ’e1n1o2
		  -5e1n1o2   entre3gent- é3quent-   équipo3tent- équiva4lent- é3rent-    er2ment-   es3cent-
		  esti2ment- ’eu2r1a2   -5eu2r1a2  .f4        'f4        ’f4        4f-        -5f4
		  fa2ment-   4fe-       fécu3lent- 2fent-     4fes-      fichu3ment- fir2ment-  flam2ment-
		  4f4le-     2f2lent-   4f4les-    4f4re-     2f2rent-   4f4res-    fu2ment-   .g4
		  'g4        ’g4        4g-        -5g4       4ge-       -5gem1me   -gem2ment- .gem2ment-
		  -5gem2ment. 2gent-     4ges-      4g4le-     2g2lent-   4g4les-    4g4ne-     2g2nent-
		  4g4nes-    gram2ment- grandilo3quent- 4g4re-     2g2rent-   4g4res-    4gue-      2guent-
		  4gues-     .h4        'h4        ’h4        4h-        -5h4       4he-       4hes-
		  hu2ment-   ’i4        4i-        .í4        'í4        ’í4        4í-        .ì4
		  'ì4        ’ì4        4ì-        ’î4        4î-        .ï4        'ï4        ’ï4
		  4ï-        -5i4       -5í4       -5ì4       -5î4       -5ï4       ’i1g2n     -5i1g2n
		  ’i2g3né    -5i2g3né   ’i2g3ni    -5i2g3ni   imma3nent- immi3nent- immis4cent- impo3tent-
		  impu3dent- ’i1n1a2    -5i1n1a2   ’ina1ni    -5ina1ni   ’in2a3nit  -5in2a3nit ’inau1gu
		  -5inau1gu  ’in2augur  -5in2augur inci3dent- indi3gent- indo3lent- indul3gent- ’i1n1e2
		  ’i1n1é2    -5i1n1e2   -5i1n1é2   ’inef1fa   -5inef1fa  ’in2effab  -5in2effab ’iné1lu
		  -5iné1lu   ’in2é3luc1ta -5in2é3luc1ta ’iné1na    -5iné1na   ’in2é3nar1ra -5in2é3nar1ra ’in2ept
		  -5in2ept   ’in2er     -5in2er    ’in2exo1ra -5in2exo1ra ’i1n1i2    -5i1n1i2   ’ini1mi
		  -5ini1mi   ’in2i3mi1ti -5in2i3mi1ti ’in2i3q    -5in2i3q   ’in2i3t    -5in2i3t   inno3cent-
		  ’i1n1o2    -5i1n1o2   ’ino1cu    -5ino1cu   ’in2o3cul  -5in2o3cul ’in2ond    -5in2ond
		  inso3lent- ’ins1ta    -5ins1ta   ’in1s2tab  -5in1s2tab ’in1te     -5in1te    intelli3gent-
		  ’inte4r3   -5inte4r3  ’inte1ra2  -5inte1ra2 ’inte1re2  ’inte1ré2  -5inte1re2 -5inte1ré2
		  ’inte1ri2  -5inte1ri2 ’inte1ro2  -5inte1ro2 ’inters2   -5inters2  ’inte1ru2  -5inte1ru2
		  inti2ment- ’i1n1u2    -5i1n1u2   ’in2uit    -5in2uit   ’in2u3l    -5in2u3l   is3cent-
		  iva3lent-  .j4        'j4        ’j4        4j-        -5j4       ja3cent-   4je-
		  2jent-     4jes-      .k4        'k4        ’k4        4k-        -5k4       4ke-
		  2kent-     4kes-      4kh-       .l4        'l4        ’l4        4l-        -5l4
		  -5la1te    -la3tent-  .la3tent-  -5la3tent. 4le-       2lent-     4les-      llu2ment-
		  l2ment-    .m4        'm4        ’m4        4m-        -5m4       -5ma2c3k   -5ma1c2r
		  -5mac1ro   -5macro1s2c -5ma1g2n   -5mag1ni   -5magni1ci -5ma2g3nici1de -5magni1fi -5magnifi1ca
		  -5ma2g3nificat -5mag1nu   -5ma2g3num -5ma1la    -5mala1d2r -5malad1re -5ma2l1a2dres -5ma2l1a2d1ro
		  -5ma2l1ai1sé -5ma2l1ap  -5ma2l1a2v -5ma1le    -5ma2l1en  -5ma1li    -5ma2l1int -5ma1lo
		  -5ma2l1oc  -5ma2l1o2d -5ma2r1x   4me-       mécon3tent- -5mé1go    -5mé2g1oh  4mes-
		  -5mé2sa    -5mé3san   -5mé1se    -5mé2s1es  -5mé2s1i   -5mé1su    -5mé2s1u2s -5mé1ta
		  -5mé1ta1s2ta -5mil3l    -5mil1li   -5milli1am mi2ment-   mit3tent-  -5mo1no    -5mono1a2
		  -5mono1e2  -5mono1é2  -5mono1i2  -5mono1ï2dé -5mono1o2  -5mono1s2  -5mono1u2  monova3lent-
		  munifi3cent- .n4        'n4        ’n4        4n-        .ñ4        'ñ4        ’ñ4
		  4ñ-        -5n4       -5ñ4       4ne-       2nent-     4nes-      -5no1no    -5no2n1obs
		  n3s2at-    n3s2ats-   nutri3ment- ’o4        4o-        .ó4        'ó4        ’ó4
		  4ó-        .ò4        'ò4        ’ò4        4ò-        ’ô4        4ô-        .õ4
		  'õ4        ’õ4        4õ-        .ø4        'ø4        ’ø4        4ø-        -5o4
		  -5ó4       -5ò4       -5ô4       -5õ4       -5ø4       .œ4        'œ4        ’œ4
		  4œ-        -5œ4       ô2ment-    om2ment-   omnipo3tent- ’on1gu     -5on1gu    -on3guent-
		  .on3guent- 'on3guent- ’on3guent- ’on3guent. -5on3guent. opu3lent-  or2ment-   ’oua1ou
		  -5oua1ou   ’o1vi      -5o1vi     ’ovi1s2c   -5ovi1s2c  .p4        'p4        ’p4
		  4p-        -5p4       -5pa1na    -5pa2n1a2f -5pa2n1a2mé -5pa2n1a2ra -5pa1ni    -5pa2n1is
		  -5pa1no    -5pa2n1o2p2h -5pa2n1opt -5pa1ra    -5para1c2h -5pa2r1a2c1he -5pa2r1a2c1hè -5para1s2
		  -5pa1re    -pa3rent-  .pa3rent-  -5pa3rent. -5pa1r2h   -5pa2r3hé  -5pa1te    -pa3tent-
		  .pa3tent-  -5pa3tent. 4pe-       2pent-     -5pen2ta   -5pe4r     -5pe1r1a2  -5pe1r1e2
		  -5pe1r1é2  -5pé1ri    -5pe1r1i2  -5péri1os  -5péri1s2  -5péri2s3s -5péri2s3ta -5péri1u2
		  perma3nent- -5pe1r1o2  perti3nent- -5pe1r1u2  4pes-      4ph-       -5p1ha     -5pha1la
		  -5phalan3s2t 4p4he-     2phent-    4p4hes-    4ph4le-    4ph4les-   4ph4re-    4ph4res-
		  4p4le-     2p2lent-   4p4les-    -5p1lu     plu2ment-  -5plu1ri   -5pluri1a  polyva3lent-
		  -5pon1te   -5pon2tet  -5pos2t3h  -5pos1ti   -5pos2t1in -5pos2t1o2 -5pos2t3r  -5post1s2
		  4p4re-     -5p1ré     -5pré1a2   -5pré2a3la -5pré2au   -5pré1e2   -5pré1é2   préémi3nent-
		  -5pré1i2   2p2rent-   -5pré1o2   4p4res-    -5pré1s2   pré3sent-  -5pré1u2   privatdo3cent-
		  privatdo3zent- -5p1ro     -5pro1é2   proémi3nent- -5pro1g2n  -5prog1na  -5pro2g3na1t2h -5pro1s2cé
		  -5prou3d2h pru3dent-  -5p1sy     -5psyc1ho  -5psycho1a2n -5pud1d2l  .q4        'q4
		  ’q4        4q-        -5q4       qua2ment-  4que-      2quent-    4ques-     .r4
		  'r4        ’r4        4r-        -5r4       rai3ment-  ra2ment-   4re-       -5ré1a2
		  -5ré2a3le  -5réa1li   -5ré2a3lis -5ré2a3lit -5ré2aux   -5ré1e2    -5ré1é2    -5ré2el
		  -5ré2er    -5ré2èr    ré3gent-   -5ré1i2    -5ré2i3fi  re3lent-   reli2ment- réma3nent-
		  2rent-     -5ré1o2    re3pent-   4res-      -5re1s2    -5res1ca   -5re2s3cap -5res1ci
		  -5re2s3ci1si -5re2s3ci1so -5res1co   -5re2s3cou -5res1c2r  -5re2s3c1ri -5res1pe   -5re2s3pect
		  -5res1pi   -5re2s3pir -5res1p2l  -5resp1le  -5re2s3plend -5res1po   -5re2s3pons -5res1q
		  -5re2s3quil -5re2s3s   -5res1se   -res3sent- .res3sent- -5res3sent. -5re2s3t   -5res1ta
		  -5re3s4tab -5re3s4tag -5re3s4tand -5re3s4tat -5res1té   -5re3s4tén -5re3s4tér -5res1ti
		  -5re3s4tim -5re3s4tip -5res1to   -5re3s4toc -5re3s4top -5re3s4t2r -5rest1re  -5re4s5trein
		  -5rest1ri  -5re4s5trict -5re4s5trin -5re3s4tu  -5re3s4ty  résur3gent- réti3cent- -5ré1t2r
		  -5rét1ro   -5rétro1a2 -5réu2     -5ré2uss   4r4he-     4r4hes-    ri2ment-   rin3gent-
		  ru3lent-   ryth2ment- .s4        's4        ’s4        4s-        .š4        'š4
		  ’š4        4š-        -5s4       -5š4       -5sar1me   -sar3ment- .sar3ment- -5sar3ment.
		  4s4ch-     4s4c4he-   4s4c4hes-  4se-       2sent-     ser3gent-  -5ser1me   -ser3ment-
		  .ser3ment- -5ser3ment. ser3pent-  4ses-      -5seu2le   4sh-       4s4he-     2shent-
		  4s4hes-    slalo2ment- -5sou1ve   -sou3vent- .sou3vent- -5sou3vent. sporu4lent- -5s1ta
		  -5sta2g3n  -5s1ti     -5stil3l   -5su2b1a2  -5su3b2alt -5su2b1é2  -5su3b2é3r -5su1bi
		  -5su2b1in  -5su1b2l   -5sub1li   subli2ment- -5subli1mi -5su2b3limin -5su2b3lin -5su2b3lu
		  -5su1bu    -5su2b1ur  succu3lent- su2ment-   -5su2r1a2  -5su3r2a3t -5su2r1e2  -5su2r1é2
		  -5su3r2eau -5su3r2ell surémi3nent- -5su3r2et  -5su2r3h   -5su1ri    -5su2r1i2m -5su2r1inf
		  -5su2r1int -5su1ro    -5su2r1of  -5su2r1ox  -5syn1g2n  -5syng1na  -5syn2g3na1t2h .t4
		  't4        ’t4        4t-        -5t4       -5ta1le    -ta3lent-  .ta3lent-  -5ta3lent.
		  ta2ment-   tan3gent-  4te-       tempéra3ment- 2tent-     ter3gent-  4tes-      testa3ment-
		  4th-       .þ4        'þ4        ’þ4        4þ-        -5þ4       4t4he-     4t4hes-
		  4th4re-    4th4res-   to2ment-   tor3rent-  transpa3rent- 4t4re-     2t2rent-   4t4res-
		  -5t1ri     -5tri1a2c  -5tri1a2n  -5tri1a2t  tri3dent-  -5tri1o2n  trucu3lent- tu2ment-
		  turbu3lent- ’u4        4u-        .ú4        'ú4        ’ú4        4ú-        .ù4
		  'ù4        ’ù4        4ù-        ’û4        4û-        .ü4        'ü4        ’ü4
		  4ü-        -5u4       -5ú4       -5ù4       -5û4       -5ü4       .v4        'v4
		  ’v4        4v-        -5v4       4ve-       veni2ment- 2vent-     ventripo3tent- 4ves-
		  vidi2ment- 4v4re-     2v2rent-   4v4res-    .w4        'w4        ’w4        4w-
		  -5w4       4we-       2went-     4wes-      .x4        'x4        ’x4        4x-
		  -5x4       2xent-     ’y4        4y-        .ý4        'ý4        ’ý4        4ý-
		  .ÿ4        'ÿ4        ’ÿ4        4ÿ-        -5y4       -5ý4       -5ÿ4       .z4
		  'z4        ’z4        4z-        .ž4        'ž4        ’ž4        4ž-        -5z4
		  -5ž4       4ze-       2zent-     4zes-      4con.
		  /
	];
}

1;    # End of Lingua::FR::Hyphen

__END__

=encoding utf8

=head1 NAME

Lingua::FR::Hyphen - Hyphenate French words

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Lingua::FR::Hyphen;
    use utf8;
      
    binmode( STDOUT, ':utf8' );
    my $hyphenator = new Lingua::FR::Hyphen;
      
    foreach (qw/  
        représentation  Montpellier avocat porte-monnaie 
        0102030405 rouge-gorge transaction consultant 
        rubicon développement UNESCO 
        /) {
        print "$_ -> " . $hyphenator->hyphenate($_) . "\n";
    }

    # représentation -> repré-sen-ta-tion
    # Montpellier -> Montpellier
    # avocat -> avo-cat
    # porte-monnaie -> porte-monnaie
    # 0102030405 -> 0102030405
    # rouge-gorge -> rouge-gorge
    # transaction -> tran-sac-tion
    # consultant -> consul-tant
    # rubicon -> rubicon
    # développement -> déve-lop-pe-ment
    # UNESCO -> UNESCO

=head1 DESCRIPTION

Lingua::FR::Hyphen hyphenates French words using Knuth Liang algorithm.

=head1 CONSTRUCTOR/METHODS

=head2 new

This constructor allows you to create a new Lingua::FR::Hyphen object.

B<$hyphenator = Lingua::FR::Hyphen-E<gt>new([OPTIONS])>

=over 4

=item B<min_word> =E<gt> I<integer>

Minimum length of word to be hyphenated. (default : 6).

  min_word => 4,

=back

=over 4

=item B<min_prefix> =E<gt> I<integer>

Minimal prefix to leave without any hyphens. (default : 3).

  min_prefix => 3,

=back

=over 4

=item B<min_suffix> =E<gt> I<integer>

Minimal suffix to leave without any hyphens. (default : 3).

  min_suffix => 3,

=back

=over 4

=item B<cut_proper_nouns> =E<gt> I<integer 0 or 1>

hyphenates or not proper nouns: (default : 0 (recommended)). 

  cut_proper_nouns => 0,

=back

=over 4

=item B<cut_compounds> =E<gt> I<integer 0 or 1>

hyphenates compounds: (default : 0 (recommended)). 

  cut_compounds => 0,

=back

=head2 hyphenate

hyphenates French words using Knuth Liang algorithm and following the rules of the French language.

B<$hyphenator-E<gt>hyphenate($word, $delimiter ? )>

Two arguments : the word and the delimiter (optionnal) (default : "-").

  $hyphenator->hyphenate($word1); 
  $hyphenator->hyphenate($word2, '/');

=head1 AUTHORS

Djibril Ousmanou, C<< <djibel at cpan.org> >>

Laurent Rosenfeld, C<< <laurent.rosenfeld at googlemail.com> >>


=head1 ACKNOWLEDGEMENTS

This module is based on the Knuth-Liang Algorithm. Frank Liang wrote his Stanford Ph.D. thesis (under the supervision of
Donald Knuth) on a hyphenation algorithm that was aimed at TeX (the typesetting utility written by Knuth) and is now standard in
Tex, and has been adapted to many open source projects such as OpenOffice, LibreOffice, Firefox, Thunderbird, etc. His 1983 PhD thesis 
can be found at L<http://www.tug.org/docs/liang/>. He invented both the "packed or compressed trie" structure for storing 
efficiently the patterns and the way to represent possible hyphens in those patterns.

This module is also partly derived from Alex Kapranoff's L<Text::Hyphen> module to hyphenate English language words.

The list of hyphenation (« césure » or « coupure de mots » in French) patterns for the French language was derived from the Dicollecte site 
(L<http://www.dicollecte.org/home.php?prj=fr>), which produces several French open source 
spell check dictionaries, used notably for Latex, OpenOffice and LibreOffice. The list of 
patterns itself can be found there: L<http://www.dicollecte.org/download/fr/hyph-fr-v3.0.zip>.

The list of proper nouns used for preventing their hyphenation (it is usually considered bad to hyphenate proper nouns
in French) was compiled from several sources, but the main source was the Hunspell dictionary for French words,
which can also be found on the Dicollect site (see L<http://www.dicollecte.org/download.php?prj=fr>) from which we extracted
proper nouns as well as acronyms (which also should no be hyphenated), although this module will not hyphenate all-capital
words anyway.


=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-fr-hyphen at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-FR-Hyphen>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

See L<Text::Hyphen>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::FR::Hyphen


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-FR-Hyphen>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-FR-Hyphen>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-FR-Hyphen>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-FR-Hyphen/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Djibril Ousmanou.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

