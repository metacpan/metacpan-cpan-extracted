use warnings;
use Math::GMPq qw(:mpq);

print "1..10\n";

print "# Using gmp version ", Math::GMPq::gmp_v(), "\n";

# Rmpq_canonicalize() is automatically run as part of new().

if(Rmpq_integer_p(Math::GMPq->new('2/-1'))) {print "ok 1\n"}
else {print "not ok 1\n"}

if(Rmpq_integer_p(Math::GMPq->new('-2/1'))) {print "ok 2\n"}
else {print "not ok 2\n"}

if(Rmpq_integer_p(Math::GMPq->new('51/3'))) {print "ok 3\n"}
else {print "not ok 3\n"}

if(!Rmpq_integer_p(Math::GMPq->new('53/-3'))) {print "ok 4\n"}
else {print "not ok 4\n"}

if(!Rmpq_integer_p(Math::GMPq->new('-53/3'))) {print "ok 5\n"}
else {print "not ok 5\n"}

if(!Rmpq_integer_p(Math::GMPq->new('54/4'))) {print "ok 6\n"}
else {print "not ok 6\n"}

if(Rmpq_integer_p(Math::GMPq->new('-2/-1'))) {print "ok 7\n"}
else {print "not ok 7\n"}

if(!Rmpq_integer_p(Math::GMPq->new('-54/-4'))) {print "ok 8\n"}
else {print "not ok 8\n"}

if(Rmpq_integer_p(Math::GMPq->new('0/-1'))) {print "ok 9\n"}
else {print "not ok 9\n"}

if(Rmpq_integer_p(Math::GMPq->new('0/1'))) {print "ok 10\n"}
else {print "not ok 10\n"}


