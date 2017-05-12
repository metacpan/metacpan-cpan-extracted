#! perl
use Test::More "no_plan";

use_ok('Inline', Spew => <<'END', SUB => 'mission');
START: missions

missions: mission "\n\n" mission "\n\n" mission "\n\n" mission "\n"

mission:
  Our_job_is_to " " do_goals "." |
  2 @ Our_job_is_to " " do_goals " " because "."

Our_job_is_to:
  ("It is our " | "It's our ") job " to" |
  "Our " job (" is to" | " is to continue to") |
  "The customer can count on us to" |
  ("We continually " | "We ") ("strive" | "envision" | "exist") " to" |
  "We have committed to" |
  "We"

job:
  "business" | "challenge" | "goal" | "job" | "mission" | "responsibility"
  
do_goals:
  goal | goal " " in_order_to " " goal

in_order_to:
  "as well as to" |
  "in order that we may" |
  "in order to" |
  "so that we may endeavor to" |
  "so that we may" |
  "such that we may continue to" |
  "to allow us to" |
  "while continuing to" |
  "and"

because:
  "because that is what the customer expects" |
  "for 100% customer satisfaction" |
  "in order to solve business problems" |
  "to exceed customer expectations" |
  "to meet our customer's needs" |
  "to set us apart from the competition" |
  "to stay competitive in tomorrow's world" |
  "while promoting personal employee growth"

goal: adverbly " " verb " " adjective " " noun

adverbly:
  "quickly" | "proactively" | "efficiently" | "assertively" |
  "interactively" | "professionally" | "authoritatively" |
  "conveniently" | "completely" | "continually" | "dramatically" |
  "enthusiastically" | "collaboratively" | "synergistically" |
  "seamlessly" | "competently" | "globally"


verb:
  "maintain" | "supply" | "provide access to" | "disseminate" |
  "network" | "create" | "engineer" | "integrate" | "leverage other's" |
  "leverage existing" | "coordinate" | "administrate" | "initiate" |
  "facilitate" | "promote" | "restore" | "fashion" | "revolutionize" |
  "build" | "enhance" | "simplify" | "pursue" | "utilize" | "foster" |
  "customize" | "negotiate"

adjective:
  "professional" | "timely" | "effective" | "unique" | "cost-effective" |
  "virtual" | "scalable" | "economically sound" |
  "inexpensive" | "value-added" | "business" | "quality" | "diverse" |
  "high-quality" | "competitive" | "excellent" | "innovative" |
  "corporate" | "high standards in" | "world-class" | "error-free" |
  "performance-based" | "multimedia-based" | "market-driven" |
  "cutting edge" | "high-payoff" | "low-risk high-yield" |
  "long-term high-impact" | "prospective" | "progressive" | "ethical" |
  "enterprise-wide" | "principle-centered" | "mission-critical" |
  "parallel" | "interdependent" | "emerging" |
  "seven-habits-conforming" | "resource-leveling"

noun:
  "content" | "paradigms" | "data" | "opportunities" |
  "information" | "services" | "materials" | "technology" | "benefits" |
  "solutions" | "infrastructures" | "products" | "deliverables" |
  "catalysts for change" | "resources" | "methods of empowerment" |
  "sources" | "leadership skills" | "meta-services" | "intellectual capital"
END

# require YAML;
diag(join " ", "result is", my $result = mission());
