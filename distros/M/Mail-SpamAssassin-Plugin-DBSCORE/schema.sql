CREATE TABLE `domains` (
  `domain` varchar(256) NOT NULL,
  `score` int(11) NOT NULL DEFAULT 0,
  UNIQUE KEY `domains_domain_IDX` (`domain`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `senders` (
  `sender` varchar(256) NOT NULL,
  `score` int(11) NOT NULL DEFAULT 0,
  UNIQUE KEY `senders_sender_IDX` (`sender`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
