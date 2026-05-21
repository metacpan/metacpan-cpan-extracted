-- rename accounts; run before map phase
UPDATE transactions SET account = 'Checking-VIP' WHERE account = 'Checking';
/* update savings; also needed */
UPDATE transactions SET account = 'Savings-VIP' WHERE account = 'Savings';
UPDATE transactions SET memo = 'foo; bar' WHERE account = 'Brokerage';
